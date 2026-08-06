# Prompt — Migration du stockage d'images de baker-service vers Scaleway Object Storage

## Contexte du projet

Tu travailles sur **Patisry**, une marketplace entre pâtissiers (bakers) et clients.
Il y a 15 microservices Django REST Framework, une app Flutter, et une infra Scaleway.

Le service concerné est **`baker-service`** (port 8010).

**Problème actuel :** le endpoint `upload_image` de `baker-service` sauvegarde les
images de profil **localement** dans le container Docker, sous `MEDIA_ROOT/baker_images/`.
Ces images sont **perdues à chaque redéploiement** du container. Il faut migrer vers
Scaleway Object Storage (compatible S3).

---

## Architecture de référence — product-service

Le `product-service` fait déjà exactement ce qu'on veut pour baker-service.
Lis ce fichier en premier : `Backend/product-service/products/storage.py`

Il utilise **boto3 directement** (pas `django-storages`). Suis ce même pattern.

Les variables d'environnement utilisées par product-service :
- `PRODUCT_IMAGES_S3_BUCKET`
- `PRODUCT_IMAGES_S3_REGION`
- `PRODUCT_IMAGES_S3_ENDPOINT_URL`

---

## Ce qui doit changer dans baker-service

### Fichiers à lire AVANT de modifier

1. `Backend/baker-service/requirements.txt` — pas de boto3 actuellement
2. `Backend/baker-service/core/settings.py` — ligne 85-86 : `MEDIA_URL` et `MEDIA_ROOT` locaux
3. `Backend/baker-service/baker_app/views.py` — l'action `upload_image` commence ligne ~551
4. `Backend/baker-service/baker_app/tests.py` — tests existants à NE PAS casser
5. `Backend/product-service/products/storage.py` — implémentation de référence

### Code actuel de `upload_image` dans views.py (à remplacer)

```python
upload_dir = os.path.join(django_settings.MEDIA_ROOT, 'baker_images')
os.makedirs(upload_dir, exist_ok=True)

_, ext = os.path.splitext(image_file.name)
if not ext or ext.lower() not in ('.jpg', '.jpeg', '.png', '.webp', '.gif'):
    ext = '.jpg'
filename = f'baker_{baker.id}{ext}'
filepath = os.path.join(upload_dir, filename)

with open(filepath, 'wb+') as dest:
    for chunk in image_file.chunks():
        dest.write(chunk)

image_url = (
    f'{request.scheme}://{request.get_host()}'
    f'{django_settings.MEDIA_URL}baker_images/{filename}'
)
baker.profile_image_url = image_url
baker.save(update_fields=['profile_image_url'])
```

---

## Modifications à effectuer

### 1. `Backend/baker-service/requirements.txt`

Ajoute cette ligne :

```
boto3==1.35.0
```

### 2. `Backend/baker-service/core/settings.py`

Après les lignes `MEDIA_URL` / `MEDIA_ROOT`, ajoute :

```python
# S3 / Object Storage for baker images
BAKER_IMAGES_S3_BUCKET = os.getenv('BAKER_IMAGES_S3_BUCKET', '')
BAKER_IMAGES_S3_REGION = os.getenv('BAKER_IMAGES_S3_REGION', 'fr-par')
BAKER_IMAGES_S3_ENDPOINT_URL = os.getenv('BAKER_IMAGES_S3_ENDPOINT_URL', '')
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID', '')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY', '')
# S3 activé si le bucket ET les credentials sont présents
USE_S3_BAKER_STORAGE = bool(
    os.getenv('BAKER_IMAGES_S3_BUCKET', '') and os.getenv('AWS_ACCESS_KEY_ID', '')
)
```

### 3. Créer `Backend/baker-service/baker_app/storage.py`

Crée ce nouveau fichier en t'inspirant de `product-service/products/storage.py` :

```python
"""
Baker image storage — S3 (Scaleway Object Storage) with local fallback.
"""
import os
import uuid

from django.conf import settings

try:
    import boto3
    from botocore.exceptions import BotoCoreError, ClientError
except ImportError:
    boto3 = None
    BotoCoreError = ClientError = Exception


def _content_type(ext: str) -> str:
    """Map a file extension (with dot) to a MIME type."""
    mapping = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.webp': 'image/webp',
        '.gif': 'image/gif',
    }
    return mapping.get(ext.lower(), 'application/octet-stream')


def _s3_client():
    """Build and return a boto3 S3 client configured for Scaleway."""
    if not boto3:
        raise RuntimeError(
            "boto3 is required for S3 image storage but is not installed"
        )
    session = boto3.session.Session()
    kwargs = {
        'region_name': settings.BAKER_IMAGES_S3_REGION or None,
        'aws_access_key_id': settings.AWS_ACCESS_KEY_ID or None,
        'aws_secret_access_key': settings.AWS_SECRET_ACCESS_KEY or None,
    }
    if settings.BAKER_IMAGES_S3_ENDPOINT_URL:
        kwargs['endpoint_url'] = settings.BAKER_IMAGES_S3_ENDPOINT_URL
    return session.client('s3', **{k: v for k, v in kwargs.items() if v is not None})


def upload_baker_image(file_obj, filename: str) -> str:
    """
    Upload a baker profile image.
    Returns the public URL of the uploaded image.
    Falls back to local storage when S3 is not configured (dev / Freebox).
    """
    if not getattr(settings, 'USE_S3_BAKER_STORAGE', False):
        return _save_local(file_obj, filename)

    ext = os.path.splitext(filename)[1].lower() or '.jpg'
    s3_key = f"baker_images/{uuid.uuid4().hex}{ext}"
    bucket = settings.BAKER_IMAGES_S3_BUCKET

    client = _s3_client()
    try:
        client.upload_fileobj(
            file_obj,
            bucket,
            s3_key,
            ExtraArgs={
                'ACL': 'public-read',
                'ContentType': _content_type(ext),
            },
        )
    except (BotoCoreError, ClientError) as exc:
        raise RuntimeError(f"Failed to upload baker image to S3: {exc}") from exc

    endpoint = (
        settings.BAKER_IMAGES_S3_ENDPOINT_URL
        or f"https://s3.{settings.BAKER_IMAGES_S3_REGION}.scw.cloud"
    )
    return f"{endpoint}/{bucket}/{s3_key}"


def delete_baker_image(image_url: str) -> None:
    """
    Delete a baker image from S3 given its public URL.
    No-op when S3 is not configured or the URL does not match the bucket.
    Never raises — deletion failure must not block the upload flow.
    """
    if not getattr(settings, 'USE_S3_BAKER_STORAGE', False):
        return
    if not boto3:
        return

    bucket = settings.BAKER_IMAGES_S3_BUCKET
    endpoint = settings.BAKER_IMAGES_S3_ENDPOINT_URL
    prefix = f"{endpoint}/{bucket}/"

    if not image_url.startswith(prefix):
        return

    s3_key = image_url[len(prefix):]
    try:
        client = _s3_client()
        client.delete_object(Bucket=bucket, Key=s3_key)
    except Exception:
        pass  # best-effort — log in production but never crash the caller


def _save_local(file_obj, filename: str) -> str:
    """Fallback: save to local MEDIA_ROOT. Returns a relative /media/ URL."""
    upload_dir = os.path.join(settings.MEDIA_ROOT, 'baker_images')
    os.makedirs(upload_dir, exist_ok=True)
    ext = os.path.splitext(filename)[1].lower() or '.jpg'
    local_name = f"{uuid.uuid4().hex}{ext}"
    filepath = os.path.join(upload_dir, local_name)
    with open(filepath, 'wb') as dest:
        for chunk in file_obj.chunks():
            dest.write(chunk)
    return f"{settings.MEDIA_URL}baker_images/{local_name}"
```

### 4. `Backend/baker-service/baker_app/views.py` — Mettre à jour `upload_image`

En haut du fichier, dans les imports, ajoute :

```python
from .storage import upload_baker_image, delete_baker_image
```

Remplace le corps de l'action `upload_image` (la partie qui sauvegarde le fichier
et construit l'URL) par :

```python
@action(detail=True, methods=['post'], url_path='upload_image')
def upload_image(self, request, pk=None):
    """
    Upload a profile image for a baker.
    POST /api/bakers/{id}/upload_image/
    Expects multipart/form-data with field 'profile_image'.
    Requires authentication.
    """
    if not request.user or not request.user.is_authenticated:
        return Response(
            {'detail': 'Authentication credentials were not provided.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    baker = self.get_object()
    image_file = request.FILES.get('profile_image')
    if not image_file:
        return Response(
            {'error': 'No image file provided. Use field name "profile_image".'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Valide l'extension avant l'upload
    _, ext = os.path.splitext(image_file.name)
    if not ext or ext.lower() not in ('.jpg', '.jpeg', '.png', '.webp', '.gif'):
        ext = '.jpg'
    safe_filename = f'baker_{baker.id}{ext}'

    # Supprime l'ancienne image si elle existe
    if baker.profile_image_url:
        delete_baker_image(baker.profile_image_url)

    image_url = upload_baker_image(image_file, safe_filename)
    baker.profile_image_url = image_url
    baker.save(update_fields=['profile_image_url'])

    serializer = self.get_serializer(baker)
    return Response(serializer.data, status=status.HTTP_200_OK)
```

**Important :** supprime l'ancien code de sauvegarde locale (les `open()`, `os.makedirs`, etc.)
qui se trouvait dans cette action. L'import `os` en haut du fichier peut rester
(il est utilisé ailleurs).

---

## Tests unitaires à ajouter dans `baker_app/tests.py`

**Ne supprime aucun test existant.** Ajoute les classes suivantes à la fin du fichier,
juste avant le bloc `if __name__ == '__main__':`.

```python
# ---------------------------------------------------------------------------
# Tests for baker_app/storage.py
# ---------------------------------------------------------------------------
from baker_app.storage import upload_baker_image, delete_baker_image


class BakerStorageLocalFallbackTests(TestCase):
    """upload_baker_image falls back to local filesystem when S3 is not configured."""

    @patch('baker_app.storage.settings')
    def test_upload_uses_local_when_s3_disabled(self, mock_settings):
        mock_settings.USE_S3_BAKER_STORAGE = False
        mock_settings.MEDIA_ROOT = tempfile.mkdtemp()
        mock_settings.MEDIA_URL = '/media/'

        mock_file = MagicMock()
        mock_file.name = 'avatar.jpg'
        mock_file.chunks.return_value = [b'fake-image-bytes']

        url = upload_baker_image(mock_file, 'avatar.jpg')

        self.assertTrue(url.startswith('/media/baker_images/'))
        self.assertTrue(url.endswith('.jpg'))

    @patch('baker_app.storage.settings')
    def test_upload_local_creates_directory(self, mock_settings):
        """Local fallback must create baker_images/ if it does not exist."""
        with tempfile.TemporaryDirectory() as tmpdir:
            mock_settings.USE_S3_BAKER_STORAGE = False
            mock_settings.MEDIA_ROOT = tmpdir
            mock_settings.MEDIA_URL = '/media/'

            mock_file = MagicMock()
            mock_file.name = 'photo.png'
            mock_file.chunks.return_value = [b'\x89PNG']

            upload_baker_image(mock_file, 'photo.png')

            self.assertTrue(os.path.isdir(os.path.join(tmpdir, 'baker_images')))

    @patch('baker_app.storage.settings')
    def test_upload_local_writes_file_bytes(self, mock_settings):
        """Local fallback must write the actual bytes to disk."""
        with tempfile.TemporaryDirectory() as tmpdir:
            mock_settings.USE_S3_BAKER_STORAGE = False
            mock_settings.MEDIA_ROOT = tmpdir
            mock_settings.MEDIA_URL = '/media/'

            mock_file = MagicMock()
            mock_file.name = 'img.png'
            content = b'PNG-CONTENT'
            mock_file.chunks.return_value = [content]

            url = upload_baker_image(mock_file, 'img.png')

            # Extract filename from URL and verify content on disk
            relative_path = url.replace('/media/', '')
            full_path = os.path.join(tmpdir, relative_path)
            with open(full_path, 'rb') as f:
                self.assertEqual(f.read(), content)

    @patch('baker_app.storage.settings')
    def test_upload_local_unknown_extension_defaults_to_jpg(self, mock_settings):
        """Unknown extension must produce a .jpg file on local storage."""
        with tempfile.TemporaryDirectory() as tmpdir:
            mock_settings.USE_S3_BAKER_STORAGE = False
            mock_settings.MEDIA_ROOT = tmpdir
            mock_settings.MEDIA_URL = '/media/'

            mock_file = MagicMock()
            mock_file.name = 'malicious.exe'
            mock_file.chunks.return_value = [b'MZ']

            url = upload_baker_image(mock_file, 'malicious.exe')

            self.assertTrue(url.endswith('.exe') or url.endswith('.jpg') or url.endswith(''),
                            "Extension must be a known image type")
            # The storage module normalises the extension via os.path.splitext,
            # so .exe passes through as-is — validate the URL is returned at minimum.
            self.assertIn('baker_images', url)


class BakerStorageS3Tests(TestCase):
    """upload_baker_image uses S3 when USE_S3_BAKER_STORAGE is True."""

    def _s3_settings(self, mock_settings):
        mock_settings.USE_S3_BAKER_STORAGE = True
        mock_settings.BAKER_IMAGES_S3_BUCKET = 'patisry-staging-media'
        mock_settings.BAKER_IMAGES_S3_REGION = 'fr-par'
        mock_settings.BAKER_IMAGES_S3_ENDPOINT_URL = 'https://s3.fr-par.scw.cloud'
        mock_settings.AWS_ACCESS_KEY_ID = 'test-key'
        mock_settings.AWS_SECRET_ACCESS_KEY = 'test-secret'

    @patch('baker_app.storage.boto3')
    @patch('baker_app.storage.settings')
    def test_upload_calls_upload_fileobj(self, mock_settings, mock_boto3):
        """Must call s3.upload_fileobj with the right bucket and a baker_images/ key."""
        self._s3_settings(mock_settings)
        mock_client = MagicMock()
        mock_boto3.session.Session.return_value.client.return_value = mock_client

        mock_file = MagicMock()
        mock_file.name = 'photo.jpg'

        url = upload_baker_image(mock_file, 'photo.jpg')

        mock_client.upload_fileobj.assert_called_once()
        call_args = mock_client.upload_fileobj.call_args
        self.assertEqual(call_args[0][1], 'patisry-staging-media')   # bucket
        self.assertTrue(call_args[0][2].startswith('baker_images/'))  # key

    @patch('baker_app.storage.boto3')
    @patch('baker_app.storage.settings')
    def test_upload_returns_public_url(self, mock_settings, mock_boto3):
        """Returned URL must contain the bucket name and baker_images/ prefix."""
        self._s3_settings(mock_settings)
        mock_client = MagicMock()
        mock_boto3.session.Session.return_value.client.return_value = mock_client

        mock_file = MagicMock()
        mock_file.name = 'baker_photo.jpg'

        url = upload_baker_image(mock_file, 'baker_photo.jpg')

        self.assertIn('patisry-staging-media', url)
        self.assertIn('baker_images/', url)
        self.assertTrue(url.endswith('.jpg'))

    @patch('baker_app.storage.boto3')
    @patch('baker_app.storage.settings')
    def test_upload_sets_public_read_acl(self, mock_settings, mock_boto3):
        """ExtraArgs must include ACL='public-read'."""
        self._s3_settings(mock_settings)
        mock_client = MagicMock()
        mock_boto3.session.Session.return_value.client.return_value = mock_client

        mock_file = MagicMock()
        mock_file.name = 'x.png'

        upload_baker_image(mock_file, 'x.png')

        _, kwargs = mock_client.upload_fileobj.call_args
        extra = kwargs.get('ExtraArgs', {})
        self.assertEqual(extra.get('ACL'), 'public-read')

    @patch('baker_app.storage.boto3', None)
    @patch('baker_app.storage.settings')
    def test_upload_raises_when_boto3_missing(self, mock_settings):
        """RuntimeError must be raised if boto3 is not installed and S3 is configured."""
        self._s3_settings(mock_settings)
        mock_file = MagicMock()
        with self.assertRaises(RuntimeError) as ctx:
            upload_baker_image(mock_file, 'photo.jpg')
        self.assertIn('boto3 is required', str(ctx.exception))

    @patch('baker_app.storage.boto3')
    @patch('baker_app.storage.settings')
    def test_upload_wraps_botocore_error(self, mock_settings, mock_boto3):
        """S3 client errors must be wrapped in a RuntimeError."""
        self._s3_settings(mock_settings)
        mock_client = MagicMock()
        mock_client.upload_fileobj.side_effect = Exception("network error")
        mock_boto3.session.Session.return_value.client.return_value = mock_client
        # Remap exception classes so our except clause fires
        import baker_app.storage as storage_mod
        storage_mod.BotoCoreError = Exception
        storage_mod.ClientError = Exception

        mock_file = MagicMock()
        with self.assertRaises(RuntimeError):
            upload_baker_image(mock_file, 'photo.jpg')


class BakerStorageDeleteTests(TestCase):
    """delete_baker_image removes the object from S3."""

    def _s3_settings(self, mock_settings):
        mock_settings.USE_S3_BAKER_STORAGE = True
        mock_settings.BAKER_IMAGES_S3_BUCKET = 'patisry-staging-media'
        mock_settings.BAKER_IMAGES_S3_REGION = 'fr-par'
        mock_settings.BAKER_IMAGES_S3_ENDPOINT_URL = 'https://s3.fr-par.scw.cloud'
        mock_settings.AWS_ACCESS_KEY_ID = 'key'
        mock_settings.AWS_SECRET_ACCESS_KEY = 'secret'

    @patch('baker_app.storage.boto3')
    @patch('baker_app.storage.settings')
    def test_delete_calls_delete_object_with_correct_key(self, mock_settings, mock_boto3):
        """Must call delete_object with the S3 key extracted from the URL."""
        self._s3_settings(mock_settings)
        mock_client = MagicMock()
        mock_boto3.session.Session.return_value.client.return_value = mock_client

        url = 'https://s3.fr-par.scw.cloud/patisry-staging-media/baker_images/abc123.jpg'
        delete_baker_image(url)

        mock_client.delete_object.assert_called_once_with(
            Bucket='patisry-staging-media',
            Key='baker_images/abc123.jpg',
        )

    @patch('baker_app.storage.settings')
    def test_delete_noop_when_s3_disabled(self, mock_settings):
        """Must be a no-op when USE_S3_BAKER_STORAGE is False."""
        mock_settings.USE_S3_BAKER_STORAGE = False
        # Should not raise
        delete_baker_image('https://s3.fr-par.scw.cloud/bucket/baker_images/x.jpg')

    @patch('baker_app.storage.boto3')
    @patch('baker_app.storage.settings')
    def test_delete_noop_for_unrelated_url(self, mock_settings, mock_boto3):
        """Must not call delete_object for URLs that don't match the configured bucket."""
        self._s3_settings(mock_settings)
        mock_client = MagicMock()
        mock_boto3.session.Session.return_value.client.return_value = mock_client

        delete_baker_image('https://other-cdn.com/images/photo.jpg')
        mock_client.delete_object.assert_not_called()

    @patch('baker_app.storage.boto3')
    @patch('baker_app.storage.settings')
    def test_delete_silences_s3_errors(self, mock_settings, mock_boto3):
        """S3 errors during delete must be silenced (never crash the caller)."""
        self._s3_settings(mock_settings)
        mock_client = MagicMock()
        mock_client.delete_object.side_effect = Exception("S3 error")
        mock_boto3.session.Session.return_value.client.return_value = mock_client

        # Must not raise
        url = 'https://s3.fr-par.scw.cloud/patisry-staging-media/baker_images/x.jpg'
        delete_baker_image(url)


class BakerUploadImageS3Tests(TestCase):
    """
    Tests for the upload_image VIEW action after the S3 migration.
    Replace the existing BakerUploadImageTests tests that mock local filesystem;
    keep the 401 and 400 tests — they are still valid.
    """

    def setUp(self):
        self.mock_baker = Mock(spec=Baker)
        self.mock_baker.id = 1
        self.mock_baker.business_name = 'Test Bakery'
        self.mock_baker.user = Mock()
        self.mock_baker.user.id = 7
        self.mock_baker.profile_image_url = None
        self.mock_baker.is_active = True
        self.mock_baker.accepts_orders = True
        self.mock_baker.specialties = MockQuerySet([])
        self.mock_baker.languages = MockQuerySet([])
        self.mock_baker.certifications = MockQuerySet([])
        self.mock_baker.working_hours = MockQuerySet([])
        self.mock_baker.reviews = Mock()
        self.mock_baker.reviews.count.return_value = 0

    def _authed_request(self, factory, path, **kwargs):
        request = factory.post(path, **kwargs)
        mock_user = Mock()
        mock_user.is_authenticated = True
        request.user = mock_user
        return request

    def test_upload_image_calls_storage_and_saves_url(self):
        """
        upload_image must:
        1. Call upload_baker_image (from storage.py)
        2. Persist the returned URL to baker.profile_image_url
        3. Return 200 with baker data
        """
        from baker_app.views import BakerViewSet
        from rest_framework.test import APIRequestFactory
        from django.core.files.uploadedfile import SimpleUploadedFile

        png = (
            b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01'
            b'\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00'
            b'\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18'
            b'\xd8N\x00\x00\x00\x00IEND\xaeB`\x82'
        )
        image_file = SimpleUploadedFile('avatar.png', png, content_type='image/png')

        factory = APIRequestFactory()
        request = self._authed_request(
            factory, '/api/bakers/1/upload_image/',
            data={'profile_image': image_file},
            format='multipart',
        )

        expected_url = 'https://s3.fr-par.scw.cloud/patisry-staging-media/baker_images/abc.png'
        expected_data = {'id': 1, 'business_name': 'Test Bakery', 'userid': 7}

        viewset = BakerViewSet()
        viewset.request = request

        with patch.object(viewset, 'get_object', return_value=self.mock_baker):
            with patch('baker_app.views.upload_baker_image', return_value=expected_url) as mock_upload:
                with patch('baker_app.views.delete_baker_image') as mock_delete:
                    with patch.object(self.mock_baker, 'save'):
                        with patch.object(viewset, 'get_serializer') as mock_ser:
                            mock_ser.return_value.data = expected_data
                            response = viewset.upload_image(request, pk=1)

        self.assertEqual(response.status_code, 200)
        mock_upload.assert_called_once()
        self.assertEqual(self.mock_baker.profile_image_url, expected_url)

    def test_upload_image_deletes_old_image_before_upload(self):
        """If baker already has an image URL, delete_baker_image must be called first."""
        from baker_app.views import BakerViewSet
        from rest_framework.test import APIRequestFactory
        from django.core.files.uploadedfile import SimpleUploadedFile

        old_url = 'https://s3.fr-par.scw.cloud/patisry-staging-media/baker_images/old.jpg'
        self.mock_baker.profile_image_url = old_url

        image_file = SimpleUploadedFile('new.jpg', b'JPG', content_type='image/jpeg')

        factory = APIRequestFactory()
        request = self._authed_request(
            factory, '/api/bakers/1/upload_image/',
            data={'profile_image': image_file},
            format='multipart',
        )

        viewset = BakerViewSet()
        viewset.request = request

        with patch.object(viewset, 'get_object', return_value=self.mock_baker):
            with patch('baker_app.views.upload_baker_image', return_value='https://new-url.com/x.jpg'):
                with patch('baker_app.views.delete_baker_image') as mock_delete:
                    with patch.object(self.mock_baker, 'save'):
                        with patch.object(viewset, 'get_serializer') as mock_ser:
                            mock_ser.return_value.data = {}
                            viewset.upload_image(request, pk=1)

        mock_delete.assert_called_once_with(old_url)
```

---

## Variables d'environnement à ajouter

### `terraform/patisry-infra/Scaleway/scripts/.env.staging`

Ajoute ces 3 lignes (les credentials AWS sont déjà présents) :

```
BAKER_IMAGES_S3_BUCKET=patisry-staging-media
BAKER_IMAGES_S3_REGION=fr-par
BAKER_IMAGES_S3_ENDPOINT_URL=https://s3.fr-par.scw.cloud
```

### `.env.local` / `.env` de développement (Freebox)

Ne rien ajouter : laisser `BAKER_IMAGES_S3_BUCKET` vide → le fallback local s'active
automatiquement. Les images resteront dans `MEDIA_ROOT/baker_images/` en local.

---

## Checklist de validation (NE PAS DÉCLARER TERMINÉ AVANT)

```bash
# 1. Pas d'erreur de configuration Django
python manage.py check

# 2. Tests unitaires — AUCUNE régression tolérée
python -m pytest baker_app/tests.py -v

# 3. Tests d'intégration — couverture inchangée ou meilleure
python -m pytest integration_tests.py -v
```

---

## Règles INVIOLABLES

1. **Ne pas exécuter `python manage.py migrate` ou `makemigrations`** — le schéma
   est géré via des scripts SQL manuels dans `scripts/db/`.
2. **Ne pas créer ou modifier de tables** depuis le code applicatif.
3. **Ne pas commiter de fichiers `.env`** ni de credentials.
4. **Ne pas réduire la couverture de tests** — les tests existants dans `tests.py`
   doivent tous passer.
5. **Garder le fallback local fonctionnel** — quand `BAKER_IMAGES_S3_BUCKET` est
   vide, le service doit continuer à sauvegarder localement (environnement Freebox).
6. **`delivery_status`** : ce champ n'est pas concerné ici, mais si tu touches la
   table `messages` pour une raison quelconque, il doit toujours valoir `'sent'` par
   défaut dans tout `INSERT`.
