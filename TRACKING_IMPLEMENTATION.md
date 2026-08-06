# User Tracking Implementation Guide

## Overview

This document provides a comprehensive guide for implementing user tracking, analytics, and monitoring features in the Patisry platform. It covers cookie management, user behavior tracking, KPI monitoring, and page view analytics.

## Implementation Strategy

### Phase 1: Basic Tracking Infrastructure

#### 1.1 User Session Management
```python
# Backend: Enhanced session tracking
class UserSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    session_token = models.CharField(max_length=255, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField()
    is_active = models.BooleanField(default=True)
    last_activity = models.DateTimeField(auto_now=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['session_token']),
            models.Index(fields=['expires_at']),
        ]
```

#### 1.2 Activity Logging
```python
# Backend: Comprehensive activity tracking
class UserActivityLog(models.Model):
    ACTION_TYPES = [
        ('page_view', 'Page View'),
        ('product_view', 'Product View'),
        ('search', 'Search'),
        ('add_to_cart', 'Add to Cart'),
        ('remove_from_cart', 'Remove from Cart'),
        ('add_favorite', 'Add Favorite'),
        ('remove_favorite', 'Remove Favorite'),
        ('login', 'Login'),
        ('logout', 'Logout'),
        ('register', 'Register'),
        ('order_placed', 'Order Placed'),
        ('review_submitted', 'Review Submitted'),
        ('message_sent', 'Message Sent'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    session_token = models.CharField(max_length=255, null=True, blank=True)
    action_type = models.CharField(max_length=50, choices=ACTION_TYPES)
    page_url = models.URLField()
    metadata = models.JSONField(default=dict)
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['user', 'action_type']),
            models.Index(fields=['created_at']),
            models.Index(fields=['action_type', 'created_at']),
        ]
```

### Phase 2: Cookie Management

#### 2.1 Cookie Consent System
```python
# Backend: Cookie consent tracking
class CookieConsent(models.Model):
    CONSENT_TYPES = [
        ('necessary', 'Necessary'),
        ('analytics', 'Analytics'),
        ('marketing', 'Marketing'),
        ('preferences', 'Preferences'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    session_token = models.CharField(max_length=255, null=True, blank=True)
    consent_type = models.CharField(max_length=20, choices=CONSENT_TYPES)
    granted = models.BooleanField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['user', 'session_token', 'consent_type']
```

#### 2.2 Frontend Cookie Management
```dart
// Frontend: Cookie service implementation
class CookieService {
  static const String _consentKey = 'cookie_consent';
  static const String _sessionKey = 'session_token';
  static const String _preferencesKey = 'user_preferences';
  
  // Get cookie consent status
  static Future<Map<String, bool>> getConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'necessary': true, // Always true
      'analytics': prefs.getBool('${_consentKey}_analytics') ?? false,
      'marketing': prefs.getBool('${_consentKey}_marketing') ?? false,
      'preferences': prefs.getBool('${_consentKey}_preferences') ?? false,
    };
  }
  
  // Set cookie consent
  static Future<void> setConsent(Map<String, bool> consent) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in consent.entries) {
      await prefs.setBool('${_consentKey}_${entry.key}', entry.value);
    }
    
    // Send consent to backend
    await _sendConsentToBackend(consent);
  }
  
  // Track user activity
  static Future<void> trackActivity(String action, Map<String, dynamic> metadata) async {
    final consent = await getConsentStatus();
    if (consent['analytics'] == true) {
      await _sendActivityToBackend(action, metadata);
    }
  }
  
  static Future<void> _sendConsentToBackend(Map<String, bool> consent) async {
    // Implementation for sending consent to backend
  }
  
  static Future<void> _sendActivityToBackend(String action, Map<String, dynamic> metadata) async {
    // Implementation for sending activity to backend
  }
}
```

### Phase 3: KPI Monitoring

#### 3.1 Real-time Analytics
```python
# Backend: KPI calculation and monitoring
class AnalyticsService:
    @staticmethod
    def calculate_user_engagement(user_id, date_range):
        """Calculate user engagement metrics"""
        activities = UserActivityLog.objects.filter(
            user_id=user_id,
            created_at__range=date_range
        )
        
        return {
            'total_actions': activities.count(),
            'unique_pages': activities.values('page_url').distinct().count(),
            'session_duration': AnalyticsService._calculate_session_duration(user_id, date_range),
            'conversion_rate': AnalyticsService._calculate_conversion_rate(user_id, date_range),
        }
    
    @staticmethod
    def calculate_baker_performance(baker_id, date_range):
        """Calculate baker performance metrics"""
        products = Product.objects.filter(baker_id=baker_id)
        
        return {
            'total_views': ProductView.objects.filter(
                product__in=products,
                viewed_at__range=date_range
            ).count(),
            'total_orders': Order.objects.filter(
                seller_id=baker_id,
                order_date__range=date_range
            ).count(),
            'revenue': Order.objects.filter(
                seller_id=baker_id,
                order_date__range=date_range
            ).aggregate(total=Sum('total_price'))['total'] or 0,
            'average_rating': BakerReview.objects.filter(
                baker_id=baker_id,
                created_at__range=date_range
            ).aggregate(avg=Avg('rating'))['avg'] or 0,
        }
    
    @staticmethod
    def calculate_product_analytics(product_id, date_range):
        """Calculate product-specific analytics"""
        return {
            'views': ProductView.objects.filter(
                product_id=product_id,
                viewed_at__range=date_range
            ).count(),
            'favorites': UserFavorite.objects.filter(
                product_id=product_id,
                added_at__range=date_range
            ).count(),
            'orders': OrderItem.objects.filter(
                product_id=product_id,
                order__order_date__range=date_range
            ).aggregate(total=Sum('quantity'))['total'] or 0,
            'revenue': OrderItem.objects.filter(
                product_id=product_id,
                order__order_date__range=date_range
            ).aggregate(total=Sum('total_price'))['total'] or 0,
        }
```

#### 3.2 Dashboard Analytics
```python
# Backend: Dashboard data aggregation
class DashboardAnalytics:
    @staticmethod
    def get_monthly_revenue(baker_id, year, month):
        """Get monthly revenue data"""
        start_date = datetime.date(year, month, 1)
        end_date = datetime.date(year, month, 28) + datetime.timedelta(days=4)
        end_date = end_date - datetime.timedelta(days=end_date.day)
        
        orders = Order.objects.filter(
            seller_id=baker_id,
            order_date__range=[start_date, end_date]
        )
        
        return orders.aggregate(
            total_revenue=Sum('total_price'),
            order_count=Count('id'),
            average_order_value=Avg('total_price')
        )
    
    @staticmethod
    def get_sales_distribution(baker_id, date_range):
        """Get sales distribution by product category"""
        return OrderItem.objects.filter(
            order__seller_id=baker_id,
            order__order_date__range=date_range
        ).values('product__categories__name').annotate(
            total_sales=Sum('total_price'),
            quantity_sold=Sum('quantity')
        ).order_by('-total_sales')
```

### Phase 4: Page View Tracking

#### 4.1 Page View Analytics
```python
# Backend: Page view tracking
class PageView(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    session_token = models.CharField(max_length=255, null=True, blank=True)
    page_url = models.URLField()
    page_title = models.CharField(max_length=255)
    referrer = models.URLField(null=True, blank=True)
    time_on_page = models.DurationField(null=True, blank=True)
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['page_url', 'created_at']),
            models.Index(fields=['user', 'created_at']),
            models.Index(fields=['created_at']),
        ]
```

#### 4.2 Frontend Page Tracking
```dart
// Frontend: Page view tracking
class PageTrackingService {
  static Timer? _pageTimer;
  static DateTime? _pageStartTime;
  static String? _currentPage;
  
  // Track page view
  static void trackPageView(String pageUrl, String pageTitle) {
    _currentPage = pageUrl;
    _pageStartTime = DateTime.now();
    
    // Send page view to backend
    _sendPageView(pageUrl, pageTitle);
    
    // Start timer for time on page
    _pageTimer?.cancel();
    _pageTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updateTimeOnPage();
    });
  }
  
  // Track page exit
  static void trackPageExit() {
    if (_currentPage != null && _pageStartTime != null) {
      final timeOnPage = DateTime.now().difference(_pageStartTime!);
      _sendTimeOnPage(_currentPage!, timeOnPage);
    }
    
    _pageTimer?.cancel();
    _currentPage = null;
    _pageStartTime = null;
  }
  
  static void _updateTimeOnPage() {
    if (_currentPage != null && _pageStartTime != null) {
      final timeOnPage = DateTime.now().difference(_pageStartTime!);
      _sendTimeOnPage(_currentPage!, timeOnPage);
    }
  }
  
  static Future<void> _sendPageView(String pageUrl, String pageTitle) async {
    // Implementation for sending page view to backend
  }
  
  static Future<void> _sendTimeOnPage(String pageUrl, Duration timeOnPage) async {
    // Implementation for sending time on page to backend
  }
}
```

### Phase 5: Advanced Analytics

#### 5.1 User Journey Tracking
```python
# Backend: User journey analysis
class UserJourney(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    session_token = models.CharField(max_length=255, null=True, blank=True)
    journey_steps = models.JSONField()  # List of page views and actions
    conversion_goal = models.CharField(max_length=100, null=True, blank=True)
    conversion_achieved = models.BooleanField(default=False)
    journey_duration = models.DurationField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['user', 'created_at']),
            models.Index(fields=['conversion_goal', 'conversion_achieved']),
        ]
```

#### 5.2 A/B Testing Framework
```python
# Backend: A/B testing support
class ABTest(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    is_active = models.BooleanField(default=True)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    variants = models.JSONField()  # List of test variants
    created_at = models.DateTimeField(auto_now_add=True)
    
class ABTestParticipation(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    test = models.ForeignKey(ABTest, on_delete=models.CASCADE)
    variant = models.CharField(max_length=50)
    assigned_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'test']
```

## Implementation Checklist

### Backend Implementation
- [ ] Create user session management tables
- [ ] Implement activity logging system
- [ ] Set up cookie consent tracking
- [ ] Create KPI calculation services
- [ ] Implement page view tracking
- [ ] Set up analytics aggregation views
- [ ] Create user journey tracking
- [ ] Implement A/B testing framework
- [ ] Set up real-time analytics endpoints
- [ ] Create data export functionality

### Frontend Implementation
- [ ] Implement cookie consent management
- [ ] Create activity tracking service
- [ ] Set up page view tracking
- [ ] Implement user journey tracking
- [ ] Create analytics dashboard
- [ ] Set up real-time KPI display
- [ ] Implement A/B testing support
- [ ] Create data visualization components
- [ ] Set up offline tracking capability
- [ ] Implement privacy controls

### Infrastructure Setup
- [ ] Set up analytics database
- [ ] Configure data retention policies
- [ ] Implement data anonymization
- [ ] Set up monitoring and alerting
- [ ] Create backup and recovery procedures
- [ ] Implement data export tools
- [ ] Set up performance monitoring
- [ ] Configure security measures
- [ ] Create compliance documentation
- [ ] Set up automated reporting

## Privacy and Compliance

### GDPR Compliance
- **Consent Management**: Clear consent for all tracking
- **Data Minimization**: Only collect necessary data
- **Right to Erasure**: User data deletion capabilities
- **Data Portability**: Export user data functionality
- **Transparency**: Clear privacy policy and data usage

### Data Security
- **Encryption**: Encrypt sensitive data at rest and in transit
- **Access Control**: Role-based access to analytics data
- **Audit Logging**: Track all data access and modifications
- **Data Retention**: Automatic data purging policies
- **Anonymization**: Remove PII from analytics data

## Performance Considerations

### Database Optimization
- **Indexing**: Strategic indexes for analytics queries
- **Partitioning**: Partition large tables by date
- **Archiving**: Move old data to archive tables
- **Caching**: Cache frequently accessed analytics
- **Query Optimization**: Optimize complex analytics queries

### Real-time Processing
- **Event Streaming**: Use message queues for real-time events
- **Batch Processing**: Process analytics in batches
- **Async Processing**: Handle tracking asynchronously
- **Rate Limiting**: Prevent tracking abuse
- **Error Handling**: Graceful handling of tracking failures

## Monitoring and Alerting

### Key Metrics to Monitor
- **User Engagement**: Page views, session duration, bounce rate
- **Conversion Rates**: Cart abandonment, order completion
- **Performance**: Page load times, API response times
- **Error Rates**: Failed tracking, API errors
- **Data Quality**: Missing data, invalid entries

### Alerting Thresholds
- **High Bounce Rate**: > 70% for key pages
- **Low Conversion**: < 2% for product pages
- **Performance Issues**: > 3s page load time
- **Error Rates**: > 5% tracking failures
- **Data Anomalies**: Unusual traffic patterns

This implementation guide provides a comprehensive framework for implementing user tracking, analytics, and monitoring in the Patisry platform while maintaining privacy compliance and performance optimization.
