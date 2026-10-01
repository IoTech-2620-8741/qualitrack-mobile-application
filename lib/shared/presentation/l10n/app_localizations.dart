// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: l10n/strings.tsv — regenerate with `python tool/generate_l10n.py`.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Localized strings for English (default) and Spanish.
class AppLocalizations {
  AppLocalizations(this.locale)
    : _values = locale.languageCode == 'es' ? _es : _en;

  final Locale locale;
  final Map<String, String> _values;

  static const List<Locale> supportedLocales = [Locale('en'), Locale('es')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations.delegate is not registered');
    return value!;
  }

  /// English is used for any unsupported device language.
  static Locale resolve(Locale? locale, Iterable<Locale> supported) {
    for (final candidate in supported) {
      if (candidate.languageCode == locale?.languageCode) return candidate;
    }
    return const Locale('en');
  }

  @visibleForTesting
  static Set<String> get englishKeys => _en.keys.toSet();

  @visibleForTesting
  static Set<String> get spanishKeys => _es.keys.toSet();

  String _t(String key) => _values[key] ?? _en[key] ?? key;

  String get appTitle => _t('appTitle');
  String get loading => _t('loading');
  String get refresh => _t('refresh');
  String get refreshing => _t('refreshing');
  String get retry => _t('retry');
  String get cancel => _t('cancel');
  String get search => _t('search');
  String get yes => _t('yes');
  String get no => _t('no');
  String get unknown => _t('unknown');
  String get noInformation => _t('noInformation');
  String get noResults => _t('noResults');
  String get filterAll => _t('filterAll');
  String get clearFilters => _t('clearFilters');
  String get previous => _t('previous');
  String get next => _t('next');
  String pageOf(int page, int total) => _t('pageOf')
      .replaceAll('{page}', '$page')
      .replaceAll('{total}', '$total');
  String get total => _t('total');
  String get status => _t('status');
  String get code => _t('code');
  String get name => _t('name');
  String get description => _t('description');
  String get type => _t('type');
  String get model => _t('model');
  String get unit => _t('unit');
  String get quantity => _t('quantity');
  String get timestamp => _t('timestamp');
  String get parameter => _t('parameter');
  String get active => _t('active');
  String get inactive => _t('inactive');
  String get normal => _t('normal');
  String get startDate => _t('startDate');
  String get endDate => _t('endDate');
  String get generalInformation => _t('generalInformation');
  String updatedAt(String time) => _t('updatedAt')
      .replaceAll('{time}', '$time');
  String calculatedAt(String date) => _t('calculatedAt')
      .replaceAll('{date}', '$date');
  String get errorTitle => _t('errorTitle');
  String get errorNetwork => _t('errorNetwork');
  String get errorTimeout => _t('errorTimeout');
  String get errorBadRequest => _t('errorBadRequest');
  String get errorCredentialsRequired => _t('errorCredentialsRequired');
  String get errorUnauthorized => _t('errorUnauthorized');
  String get errorForbidden => _t('errorForbidden');
  String get errorOnboarding => _t('errorOnboarding');
  String get errorNotFound => _t('errorNotFound');
  String get errorConflict => _t('errorConflict');
  String get errorServer => _t('errorServer');
  String get errorParsing => _t('errorParsing');
  String get errorMissingLaboratory => _t('errorMissingLaboratory');
  String get errorUnexpected => _t('errorUnexpected');
  String get checkingSession => _t('checkingSession');
  String get signInTitle => _t('signInTitle');
  String get signInSubtitle => _t('signInSubtitle');
  String get username => _t('username');
  String get usernameHint => _t('usernameHint');
  String get usernameRequired => _t('usernameRequired');
  String get password => _t('password');
  String get passwordHint => _t('passwordHint');
  String get passwordRequired => _t('passwordRequired');
  String get showPassword => _t('showPassword');
  String get hidePassword => _t('hidePassword');
  String get signIn => _t('signIn');
  String get signingIn => _t('signingIn');
  String get invalidCredentials => _t('invalidCredentials');
  String get sessionExpired => _t('sessionExpired');
  String get accountsManagedOnWeb => _t('accountsManagedOnWeb');
  String get signOut => _t('signOut');
  String get signOutConfirm => _t('signOutConfirm');
  String get setupRequiredTitle => _t('setupRequiredTitle');
  String get setupSubscriptionMissing => _t('setupSubscriptionMissing');
  String get setupLaboratoryMissing => _t('setupLaboratoryMissing');
  String get setupGeneric => _t('setupGeneric');
  String get setupRequiredHint => _t('setupRequiredHint');
  String get checkAgain => _t('checkAgain');
  String get roleAdmin => _t('roleAdmin');
  String get roleQaManager => _t('roleQaManager');
  String get roleLabOperator => _t('roleLabOperator');
  String get navHome => _t('navHome');
  String get navTelemetry => _t('navTelemetry');
  String get navAlerts => _t('navAlerts');
  String get navBatches => _t('navBatches');
  String get navMore => _t('navMore');
  String get more => _t('more');
  String get profile => _t('profile');
  String get about => _t('about');
  String versionLabel(String version) => _t('versionLabel')
      .replaceAll('{version}', '$version');
  String get aboutDescription => _t('aboutDescription');
  String get aboutWebScope => _t('aboutWebScope');
  String get laboratory => _t('laboratory');
  String laboratoryNumber(String id) => _t('laboratoryNumber')
      .replaceAll('{id}', '$id');
  String get ruc => _t('ruc');
  String get phone => _t('phone');
  String get address => _t('address');
  String get regulations => _t('regulations');
  String get commandCenterTitle => _t('commandCenterTitle');
  String get commandCenterSubtitle => _t('commandCenterSubtitle');
  String welcomeUser(String name) => _t('welcomeUser')
      .replaceAll('{name}', '$name');
  String get keyOperationalMetrics => _t('keyOperationalMetrics');
  String get openAlerts => _t('openAlerts');
  String get rawMaterials => _t('rawMaterials');
  String operationalCount(int count) => _t('operationalCount')
      .replaceAll('{count}', '$count');
  String pendingInProgress(int pending, int inProgress) => _t('pendingInProgress')
      .replaceAll('{pending}', '$pending')
      .replaceAll('{inProgress}', '$inProgress');
  String criticalCount(int count) => _t('criticalCount')
      .replaceAll('{count}', '$count');
  String lowStockCount(int count) => _t('lowStockCount')
      .replaceAll('{count}', '$count');
  String criticalAlertsCount(int count) => _t('criticalAlertsCount')
      .replaceAll('{count}', '$count');
  String get noCriticalAlerts => _t('noCriticalAlerts');
  String get liveTelemetry => _t('liveTelemetry');
  String get liveTelemetryHint => _t('liveTelemetryHint');
  String onlineOfTotal(int online, int total) => _t('onlineOfTotal')
      .replaceAll('{online}', '$online')
      .replaceAll('{total}', '$total');
  String get onlineDevices => _t('onlineDevices');
  String get telemetryAttention => _t('telemetryAttention');
  String get withoutStatus => _t('withoutStatus');
  String get riskOverview => _t('riskOverview');
  String get riskOverviewHint => _t('riskOverviewHint');
  String get lowStock => _t('lowStock');
  String get kpisAtRisk => _t('kpisAtRisk');
  String itemsCount(int count) => _t('itemsCount')
      .replaceAll('{count}', '$count');
  String get overallHealth => _t('overallHealth');
  String get equipmentTitle => _t('equipmentTitle');
  String get equipmentDetail => _t('equipmentDetail');
  String get equipmentEmpty => _t('equipmentEmpty');
  String equipmentSummary(int total, int attention) => _t('equipmentSummary')
      .replaceAll('{total}', '$total')
      .replaceAll('{attention}', '$attention');
  String get searchEquipment => _t('searchEquipment');
  String get needsAttention => _t('needsAttention');
  String get equipmentOperational => _t('equipmentOperational');
  String get equipmentMaintenance => _t('equipmentMaintenance');
  String get equipmentOutOfService => _t('equipmentOutOfService');
  String get equipment => _t('equipment');
  String equipmentNumber(int id) => _t('equipmentNumber')
      .replaceAll('{id}', '$id');
  String get serialNumber => _t('serialNumber');
  String get linkedSensor => _t('linkedSensor');
  String get sensorLinked => _t('sensorLinked');
  String get noSensor => _t('noSensor');
  String get telemetryStatus => _t('telemetryStatus');
  String get lastHeartbeat => _t('lastHeartbeat');
  String get viewTelemetry => _t('viewTelemetry');
  String get bpmLimits => _t('bpmLimits');
  String get bpmLimitsEmpty => _t('bpmLimitsEmpty');
  String get maintenanceHistory => _t('maintenanceHistory');
  String get maintenanceEmpty => _t('maintenanceEmpty');
  String get deviationTrends => _t('deviationTrends');
  String dataPointsCount(int count) => _t('dataPointsCount')
      .replaceAll('{count}', '$count');
  String get trendIncreasing => _t('trendIncreasing');
  String get trendDecreasing => _t('trendDecreasing');
  String get trendStable => _t('trendStable');
  String get complianceEvents => _t('complianceEvents');
  String get auditLog => _t('auditLog');
  String get telemetryTitle => _t('telemetryTitle');
  String get telemetrySubtitle => _t('telemetrySubtitle');
  String get liveUpdates => _t('liveUpdates');
  String get selectEquipment => _t('selectEquipment');
  String get telemetryOperational => _t('telemetryOperational');
  String get telemetryWarning => _t('telemetryWarning');
  String get telemetryCritical => _t('telemetryCritical');
  String get telemetryOffline => _t('telemetryOffline');
  String get telemetryUnavailable => _t('telemetryUnavailable');
  String get online => _t('online');
  String get offline => _t('offline');
  String get connectionStatus => _t('connectionStatus');
  String get detectedAnomalies => _t('detectedAnomalies');
  String eventsCount(int count) => _t('eventsCount')
      .replaceAll('{count}', '$count');
  String get anomaliesLast24h => _t('anomaliesLast24h');
  String get liveTelemetryStream => _t('liveTelemetryStream');
  String get window15m => _t('window15m');
  String get window1h => _t('window1h');
  String get window6h => _t('window6h');
  String get window24h => _t('window24h');
  String get anomaly => _t('anomaly');
  String get noHistoryInRange => _t('noHistoryInRange');
  String chartSemantics(int count, String unit) => _t('chartSemantics')
      .replaceAll('{count}', '$count')
      .replaceAll('{unit}', '$unit');
  String get currentReadings => _t('currentReadings');
  String get noMeasurements => _t('noMeasurements');
  String targetRange(String min, String max, String unit) => _t('targetRange')
      .replaceAll('{min}', '$min')
      .replaceAll('{max}', '$max')
      .replaceAll('{unit}', '$unit');
  String get withinLimits => _t('withinLimits');
  String get outOfLimits => _t('outOfLimits');
  String get activeTelemetryEvents => _t('activeTelemetryEvents');
  String get noAnomalies => _t('noAnomalies');
  String get bpmDeviation => _t('bpmDeviation');
  String get rawTelemetryLog => _t('rawTelemetryLog');
  String get rawTelemetrySubtitle => _t('rawTelemetrySubtitle');
  String get dateRangeAll => _t('dateRangeAll');
  String get onlyAnomalies => _t('onlyAnomalies');
  String liveEntries(int count) => _t('liveEntries')
      .replaceAll('{count}', '$count');
  String get recordedValue => _t('recordedValue');
  String get alertsTitle => _t('alertsTitle');
  String get alertsSubtitle => _t('alertsSubtitle');
  String get alertsEmptyTitle => _t('alertsEmptyTitle');
  String get alertsEmptyMessage => _t('alertsEmptyMessage');
  String get totalAlerts => _t('totalAlerts');
  String get criticalOpen => _t('criticalOpen');
  String get alertUnresolved => _t('alertUnresolved');
  String get alertAcknowledged => _t('alertAcknowledged');
  String get alertResolved => _t('alertResolved');
  String get severity => _t('severity');
  String get severityLow => _t('severityLow');
  String get severityWarning => _t('severityWarning');
  String get severityCritical => _t('severityCritical');
  String alertNumber(int id) => _t('alertNumber')
      .replaceAll('{id}', '$id');
  String get batch => _t('batch');
  String batchNumberShort(int id) => _t('batchNumberShort')
      .replaceAll('{id}', '$id');
  String userNumber(int id) => _t('userNumber')
      .replaceAll('{id}', '$id');
  String get deviationDetails => _t('deviationDetails');
  String get technicalInspection => _t('technicalInspection');
  String get thresholdValue => _t('thresholdValue');
  String get acknowledgedBy => _t('acknowledgedBy');
  String get resolvedBy => _t('resolvedBy');
  String get resolutionNotes => _t('resolutionNotes');
  String get resolutionNotesHint => _t('resolutionNotesHint');
  String get resolutionNotesRequired => _t('resolutionNotesRequired');
  String get reviewActions => _t('reviewActions');
  String get reviewRestricted => _t('reviewRestricted');
  String get acknowledge => _t('acknowledge');
  String get acknowledgeAlert => _t('acknowledgeAlert');
  String get acknowledgeConfirm => _t('acknowledgeConfirm');
  String get markAsResolved => _t('markAsResolved');
  String get resolveConfirm => _t('resolveConfirm');
  String get alertAcknowledgedMessage => _t('alertAcknowledgedMessage');
  String get alertResolvedMessage => _t('alertResolvedMessage');
  String get batchesTitle => _t('batchesTitle');
  String get batchesSubtitle => _t('batchesSubtitle');
  String get batchesEmpty => _t('batchesEmpty');
  String get searchBatches => _t('searchBatches');
  String get batchPending => _t('batchPending');
  String get batchInProgress => _t('batchInProgress');
  String get batchReleased => _t('batchReleased');
  String get batchRejected => _t('batchRejected');
  String get product => _t('product');
  String get awaitingQaRelease => _t('awaitingQaRelease');
  String get batchDetail => _t('batchDetail');
  String get rawMaterialsUsed => _t('rawMaterialsUsed');
  String get traceability => _t('traceability');
  String get bpmNotes => _t('bpmNotes');
  String get qaReview => _t('qaReview');
  String get qaReviewHint => _t('qaReviewHint');
  String get releaseBatch => _t('releaseBatch');
  String get rejectBatch => _t('rejectBatch');
  String get releaseDate => _t('releaseDate');
  String get rejectionDate => _t('rejectionDate');
  String get qualityReleaseNotes => _t('qualityReleaseNotes');
  String get releaseNotesHint => _t('releaseNotesHint');
  String get releaseNotesRequired => _t('releaseNotesRequired');
  String get rejectionReason => _t('rejectionReason');
  String get rejectionReasonHint => _t('rejectionReasonHint');
  String get rejectionReasonRequired => _t('rejectionReasonRequired');
  String releaseConfirm(String batch) => _t('releaseConfirm')
      .replaceAll('{batch}', '$batch');
  String rejectConfirm(String batch) => _t('rejectConfirm')
      .replaceAll('{batch}', '$batch');
  String get batchReleasedMessage => _t('batchReleasedMessage');
  String get batchRejectedMessage => _t('batchRejectedMessage');
  String get rawMaterialUsageHistory => _t('rawMaterialUsageHistory');
  String get rawMaterialsUsedEmpty => _t('rawMaterialsUsedEmpty');
  String materialNumber(int id) => _t('materialNumber')
      .replaceAll('{id}', '$id');
  String stockBeforeAfter(String before, String after) => _t('stockBeforeAfter')
      .replaceAll('{before}', '$before')
      .replaceAll('{after}', '$after');
  String receiptNumber(int id) => _t('receiptNumber')
      .replaceAll('{id}', '$id');
  String get batchNoAlerts => _t('batchNoAlerts');
  String get inventoryTitle => _t('inventoryTitle');
  String get inventoryEmpty => _t('inventoryEmpty');
  String materialsCount(int count) => _t('materialsCount')
      .replaceAll('{count}', '$count');
  String lowStockAlert(int count) => _t('lowStockAlert')
      .replaceAll('{count}', '$count');
  String get searchMaterials => _t('searchMaterials');
  String get belowMinimum => _t('belowMinimum');
  String get blockedStock => _t('blockedStock');
  String get stockOk => _t('stockOk');
  String get usableStock => _t('usableStock');
  String get physicalStock => _t('physicalStock');
  String get minimumStock => _t('minimumStock');
  String get materialDetail => _t('materialDetail');
  String get receipts => _t('receipts');
  String get receiptsEmpty => _t('receiptsEmpty');
  String get supplier => _t('supplier');
  String get initialAmount => _t('initialAmount');
  String get availableAmount => _t('availableAmount');
  String get receivedOn => _t('receivedOn');
  String get expiresOn => _t('expiresOn');
  String get usable => _t('usable');
  String get receiptQuarantined => _t('receiptQuarantined');
  String get receiptReleased => _t('receiptReleased');
  String get receiptObserved => _t('receiptObserved');
  String get receiptRejected => _t('receiptRejected');
  String get movements => _t('movements');
  String get movementsEmpty => _t('movementsEmpty');
  String get productsTitle => _t('productsTitle');
  String get productsEmpty => _t('productsEmpty');
  String productsCount(int count) => _t('productsCount')
      .replaceAll('{count}', '$count');
  String get searchProducts => _t('searchProducts');
  String get productDetail => _t('productDetail');
  String get bpmSpecifications => _t('bpmSpecifications');
  String get reportsTitle => _t('reportsTitle');
  String get reportsSubtitle => _t('reportsSubtitle');
  String get reportsEmpty => _t('reportsEmpty');
  String get kpiDashboard => _t('kpiDashboard');
  String get kpiEmpty => _t('kpiEmpty');
  String get kpiOnTrack => _t('kpiOnTrack');
  String get kpiAtRisk => _t('kpiAtRisk');
  String targetValue(String value) => _t('targetValue')
      .replaceAll('{value}', '$value');
  String get reportHistory => _t('reportHistory');
  String get reportHistoryEmpty => _t('reportHistoryEmpty');
  String get billingTitle => _t('billingTitle');
  String get billingSubtitle => _t('billingSubtitle');
  String get billingEmpty => _t('billingEmpty');
  String get currentSubscription => _t('currentSubscription');
  String get noActiveSubscription => _t('noActiveSubscription');
  String get plan => _t('plan');
  String get billingCycle => _t('billingCycle');
  String get periodStart => _t('periodStart');
  String get periodEnd => _t('periodEnd');
  String get amount => _t('amount');
  String get maxUsers => _t('maxUsers');
  String get maxEquipment => _t('maxEquipment');
  String get paymentHistory => _t('paymentHistory');
  String get paymentsEmpty => _t('paymentsEmpty');
  String get provider => _t('provider');
  String get subscriptionHistory => _t('subscriptionHistory');
  String get billingManagedOnWeb => _t('billingManagedOnWeb');
}

const Map<String, String> _en = {
  'appTitle': 'QualiTrack Mobile',
  'loading': 'Loading…',
  'refresh': 'Refresh',
  'refreshing': 'Refreshing…',
  'retry': 'Retry',
  'cancel': 'Cancel',
  'search': 'Search',
  'yes': 'Yes',
  'no': 'No',
  'unknown': 'Unknown',
  'noInformation': 'No information available',
  'noResults': 'No results match the current filters',
  'filterAll': 'All',
  'clearFilters': 'Clear filters',
  'previous': 'Previous',
  'next': 'Next',
  'pageOf': 'Page {page} of {total}',
  'total': 'Total',
  'status': 'Status',
  'code': 'Code',
  'name': 'Name',
  'description': 'Description',
  'type': 'Type',
  'model': 'Model',
  'unit': 'Unit',
  'quantity': 'Quantity',
  'timestamp': 'Timestamp',
  'parameter': 'Parameter',
  'active': 'Active',
  'inactive': 'Inactive',
  'normal': 'Normal',
  'startDate': 'Start date',
  'endDate': 'End date',
  'generalInformation': 'General information',
  'updatedAt': 'Updated at {time}',
  'calculatedAt': 'Calculated: {date}',
  'errorTitle': 'Something went wrong',
  'errorNetwork': 'No connection to QualiTrack. Check your internet connection or the API address.',
  'errorTimeout': 'The server took too long to respond. Try again.',
  'errorBadRequest': 'The request was rejected by QualiTrack.',
  'errorCredentialsRequired': 'Enter your username and password.',
  'errorUnauthorized': 'Your session is no longer valid. Sign in again.',
  'errorForbidden': 'You do not have access to this information.',
  'errorOnboarding': 'Your account setup is incomplete. Complete it in QualiTrack Web.',
  'errorNotFound': 'The requested information was not found.',
  'errorConflict': 'The operation conflicts with the current state.',
  'errorServer': 'QualiTrack is not available right now. Try again later.',
  'errorParsing': 'The server response could not be read.',
  'errorMissingLaboratory': 'Your account has no laboratory assigned. Complete the setup in QualiTrack Web.',
  'errorUnexpected': 'An unexpected error occurred.',
  'checkingSession': 'Checking session',
  'signInTitle': 'Sign In',
  'signInSubtitle': 'Welcome back to QualiTrack.',
  'username': 'Username',
  'usernameHint': 'name@company.com',
  'usernameRequired': 'Username is required',
  'password': 'Password',
  'passwordHint': 'Your password',
  'passwordRequired': 'Password is required',
  'showPassword': 'Show password',
  'hidePassword': 'Hide password',
  'signIn': 'Sign In',
  'signingIn': 'Signing in',
  'invalidCredentials': 'Invalid username or password.',
  'sessionExpired': 'Your session has expired. Please sign in again.',
  'accountsManagedOnWeb': 'Accounts are created and managed in QualiTrack Web.',
  'signOut': 'Sign out',
  'signOutConfirm': 'Do you want to sign out of QualiTrack?',
  'setupRequiredTitle': 'Complete your setup in QualiTrack Web',
  'setupSubscriptionMissing': 'Your laboratory does not have an active subscription yet.',
  'setupLaboratoryMissing': 'Your account is not linked to a laboratory yet.',
  'setupGeneric': 'Your account setup is not complete.',
  'setupRequiredHint': 'Subscriptions, laboratories and users are configured from the web application. Come back once it is done.',
  'checkAgain': 'Check again',
  'roleAdmin': 'Administrator',
  'roleQaManager': 'QA Manager',
  'roleLabOperator': 'Lab Operator',
  'navHome': 'Home',
  'navTelemetry': 'Telemetry',
  'navAlerts': 'Alerts',
  'navBatches': 'Batches',
  'navMore': 'More',
  'more': 'More',
  'profile': 'Profile',
  'about': 'About',
  'versionLabel': 'Version {version}',
  'aboutDescription': 'QualiTrack Mobile is the monitoring and review companion of the QualiTrack pharmaceutical quality management platform: telemetry, deviation alerts, production batches, inventory and billing at a glance.',
  'aboutWebScope': 'Configuration and data registration (laboratories, products, materials, equipment, sensors, limits, batches, users and subscriptions) are performed in QualiTrack Web.',
  'laboratory': 'Laboratory',
  'laboratoryNumber': 'Laboratory {id}',
  'ruc': 'RUC',
  'phone': 'Phone',
  'address': 'Address',
  'regulations': 'Applicable regulations',
  'commandCenterTitle': 'Command Center',
  'commandCenterSubtitle': 'Operational overview across laboratory, equipment, batches, reports and telemetry.',
  'welcomeUser': 'Hello, {name}',
  'keyOperationalMetrics': 'Key operational metrics',
  'openAlerts': 'Open alerts',
  'rawMaterials': 'Raw materials',
  'operationalCount': '{count} operational',
  'pendingInProgress': '{pending} pending · {inProgress} in progress',
  'criticalCount': '{count} critical',
  'lowStockCount': '{count} low stock',
  'criticalAlertsCount': '{count} critical alerts open',
  'noCriticalAlerts': 'No critical alerts open',
  'liveTelemetry': 'Live telemetry',
  'liveTelemetryHint': 'Latest equipment monitoring signal',
  'onlineOfTotal': '{online} of {total} equipment online',
  'onlineDevices': 'Online',
  'telemetryAttention': 'Telemetry warnings',
  'withoutStatus': 'No status',
  'riskOverview': 'Risk overview',
  'riskOverviewHint': 'Items that may require operational attention',
  'lowStock': 'Low stock',
  'kpisAtRisk': 'KPIs at risk',
  'itemsCount': '{count} items',
  'overallHealth': 'Overall health',
  'equipmentTitle': 'Equipment',
  'equipmentDetail': 'Equipment detail',
  'equipmentEmpty': 'No equipment has been registered in QualiTrack Web yet.',
  'equipmentSummary': '{total} registered · {attention} need attention',
  'searchEquipment': 'Search by name, model or serial',
  'needsAttention': 'Needs attention',
  'equipmentOperational': 'Operational',
  'equipmentMaintenance': 'Maintenance',
  'equipmentOutOfService': 'Out of service',
  'equipment': 'Equipment',
  'equipmentNumber': 'Equipment #{id}',
  'serialNumber': 'Serial number',
  'linkedSensor': 'Linked sensor',
  'sensorLinked': 'Sensor linked',
  'noSensor': 'No sensor',
  'telemetryStatus': 'Telemetry status',
  'lastHeartbeat': 'Last heartbeat',
  'viewTelemetry': 'View telemetry',
  'bpmLimits': 'BPM limits',
  'bpmLimitsEmpty': 'No BPM limits configured.',
  'maintenanceHistory': 'Maintenance history',
  'maintenanceEmpty': 'No maintenance records.',
  'deviationTrends': 'Deviation trends',
  'dataPointsCount': '{count} data points',
  'trendIncreasing': 'Increasing',
  'trendDecreasing': 'Decreasing',
  'trendStable': 'Stable',
  'complianceEvents': 'Compliance events',
  'auditLog': 'Audit log',
  'telemetryTitle': 'Telemetry Dashboard',
  'telemetrySubtitle': 'Real-time sensory data and parameter monitoring',
  'liveUpdates': 'Live · 15 s',
  'selectEquipment': 'Select equipment',
  'telemetryOperational': 'Operational',
  'telemetryWarning': 'Warning',
  'telemetryCritical': 'Critical',
  'telemetryOffline': 'Offline',
  'telemetryUnavailable': 'Telemetry unavailable',
  'online': 'Online',
  'offline': 'Offline',
  'connectionStatus': 'Connection status',
  'detectedAnomalies': 'Detected anomalies',
  'eventsCount': '{count} events',
  'anomaliesLast24h': 'Anomalies in the last 24 h',
  'liveTelemetryStream': 'Live telemetry stream',
  'window15m': '15 min',
  'window1h': '1 h',
  'window6h': '6 h',
  'window24h': '24 h',
  'anomaly': 'Anomaly',
  'noHistoryInRange': 'No telemetry history for this range',
  'chartSemantics': 'Telemetry chart with {count} readings {unit}',
  'currentReadings': 'Current sensor readings',
  'noMeasurements': 'This equipment has not reported measurements yet.',
  'targetRange': 'Target: {min} – {max} {unit}',
  'withinLimits': 'Within limits',
  'outOfLimits': 'Out of limits',
  'activeTelemetryEvents': 'Active telemetry events',
  'noAnomalies': 'No anomalies detected.',
  'bpmDeviation': 'BPM deviation',
  'rawTelemetryLog': 'Raw telemetry data log',
  'rawTelemetrySubtitle': 'Sensory logs and BPM deviation records',
  'dateRangeAll': 'Date range: all',
  'onlyAnomalies': 'Only anomalies',
  'liveEntries': 'Entries ({count})',
  'recordedValue': 'Recorded value',
  'alertsTitle': 'Compliance Alerts',
  'alertsSubtitle': 'Deviation alerts generated by QualiTrack',
  'alertsEmptyTitle': 'No deviation alerts',
  'alertsEmptyMessage': 'All monitored parameters are within limits.',
  'totalAlerts': 'Total alerts',
  'criticalOpen': 'Critical open',
  'alertUnresolved': 'Unresolved',
  'alertAcknowledged': 'Acknowledged',
  'alertResolved': 'Resolved',
  'severity': 'Severity',
  'severityLow': 'Low',
  'severityWarning': 'Warning',
  'severityCritical': 'Critical',
  'alertNumber': 'Alert #{id}',
  'batch': 'Batch',
  'batchNumberShort': 'Batch #{id}',
  'userNumber': 'User #{id}',
  'deviationDetails': 'Deviation details',
  'technicalInspection': 'Technical inspection',
  'thresholdValue': 'Threshold value',
  'acknowledgedBy': 'Acknowledged by',
  'resolvedBy': 'Resolved by',
  'resolutionNotes': 'Resolution notes',
  'resolutionNotesHint': 'Describe the corrective action and verification',
  'resolutionNotesRequired': 'Resolution notes are required',
  'reviewActions': 'Review actions',
  'reviewRestricted': 'Review actions are available to QA Managers and Administrators.',
  'acknowledge': 'Acknowledge',
  'acknowledgeAlert': 'Acknowledge alert',
  'acknowledgeConfirm': 'Confirm that you have reviewed this deviation.',
  'markAsResolved': 'Mark as resolved',
  'resolveConfirm': 'The alert will be closed with your resolution notes.',
  'alertAcknowledgedMessage': 'Alert acknowledged',
  'alertResolvedMessage': 'Alert resolved',
  'batchesTitle': 'Production Batches',
  'batchesSubtitle': 'Traceability and quality control of production cycles',
  'batchesEmpty': 'No production batches have been registered in QualiTrack Web yet.',
  'searchBatches': 'Search by batch number or product',
  'batchPending': 'Pending',
  'batchInProgress': 'In progress',
  'batchReleased': 'Released',
  'batchRejected': 'Rejected',
  'product': 'Product',
  'awaitingQaRelease': 'Awaiting QA release',
  'batchDetail': 'Batch detail',
  'rawMaterialsUsed': 'Raw materials used',
  'traceability': 'Traceability',
  'bpmNotes': 'BPM notes',
  'qaReview': 'QA review',
  'qaReviewHint': 'Release or reject this existing batch. QualiTrack validates the transition.',
  'releaseBatch': 'Release batch',
  'rejectBatch': 'Reject batch',
  'releaseDate': 'Release date',
  'rejectionDate': 'Rejection date',
  'qualityReleaseNotes': 'Quality release notes',
  'releaseNotesHint': 'Compliance release notes and verification observations',
  'releaseNotesRequired': 'Release notes are required',
  'rejectionReason': 'Rejection reason',
  'rejectionReasonHint': 'Regulatory cause or BPM non-conformity',
  'rejectionReasonRequired': 'A rejection reason is required',
  'releaseConfirm': 'Release batch {batch}? This action cannot be undone from the app.',
  'rejectConfirm': 'Reject batch {batch}? This action cannot be undone from the app.',
  'batchReleasedMessage': 'Batch released',
  'batchRejectedMessage': 'Batch rejected',
  'rawMaterialUsageHistory': 'Raw material usage history',
  'rawMaterialsUsedEmpty': 'No raw materials were consumed by this batch.',
  'materialNumber': 'Material #{id}',
  'stockBeforeAfter': 'Stock {before} → {after}',
  'receiptNumber': 'Receipt #{id}',
  'batchNoAlerts': 'No deviation alerts for this batch.',
  'inventoryTitle': 'Raw Materials Inventory',
  'inventoryEmpty': 'No raw materials have been registered in QualiTrack Web yet.',
  'materialsCount': '{count} materials',
  'lowStockAlert': '{count} materials are below the minimum stock',
  'searchMaterials': 'Search by name or code',
  'belowMinimum': 'Below minimum',
  'blockedStock': 'Blocked stock',
  'stockOk': 'Stock OK',
  'usableStock': 'Usable stock',
  'physicalStock': 'Physical stock',
  'minimumStock': 'Minimum stock',
  'materialDetail': 'Material detail',
  'receipts': 'Supplier receipts',
  'receiptsEmpty': 'No receipts registered.',
  'supplier': 'Supplier',
  'initialAmount': 'Initial amount',
  'availableAmount': 'Available amount',
  'receivedOn': 'Received',
  'expiresOn': 'Expires',
  'usable': 'Usable',
  'receiptQuarantined': 'Quarantined',
  'receiptReleased': 'Released',
  'receiptObserved': 'Observed',
  'receiptRejected': 'Rejected',
  'movements': 'Stock movements',
  'movementsEmpty': 'No movements recorded.',
  'productsTitle': 'Pharmaceutical Product Catalog',
  'productsEmpty': 'No products have been registered in QualiTrack Web yet.',
  'productsCount': '{count} registered products',
  'searchProducts': 'Search by code or name',
  'productDetail': 'Product detail',
  'bpmSpecifications': 'BPM specifications',
  'reportsTitle': 'Reports & KPIs',
  'reportsSubtitle': 'KPI dashboard and generated reports',
  'reportsEmpty': 'No KPI dashboard or reports have been generated in QualiTrack Web yet.',
  'kpiDashboard': 'KPI dashboard',
  'kpiEmpty': 'No KPI dashboard has been calculated yet.',
  'kpiOnTrack': 'On track',
  'kpiAtRisk': 'At risk',
  'targetValue': 'Target: {value}',
  'reportHistory': 'Report history',
  'reportHistoryEmpty': 'No reports generated.',
  'billingTitle': 'Billing Summary',
  'billingSubtitle': 'Your active subscription and payment history',
  'billingEmpty': 'No subscriptions found for this laboratory.',
  'currentSubscription': 'Current subscription',
  'noActiveSubscription': 'No active subscription',
  'plan': 'Plan',
  'billingCycle': 'Billing cycle',
  'periodStart': 'Period start',
  'periodEnd': 'Period end',
  'amount': 'Amount',
  'maxUsers': 'Max users',
  'maxEquipment': 'Max equipment',
  'paymentHistory': 'Payment history',
  'paymentsEmpty': 'No payments recorded.',
  'provider': 'Provider',
  'subscriptionHistory': 'Subscription history',
  'billingManagedOnWeb': 'Plan changes, checkout and cancellation are managed in QualiTrack Web.',
};

const Map<String, String> _es = {
  'appTitle': 'QualiTrack Mobile',
  'loading': 'Cargando…',
  'refresh': 'Actualizar',
  'refreshing': 'Actualizando…',
  'retry': 'Reintentar',
  'cancel': 'Cancelar',
  'search': 'Buscar',
  'yes': 'Sí',
  'no': 'No',
  'unknown': 'Desconocido',
  'noInformation': 'Sin información disponible',
  'noResults': 'No hay resultados para los filtros actuales',
  'filterAll': 'Todos',
  'clearFilters': 'Limpiar filtros',
  'previous': 'Anterior',
  'next': 'Siguiente',
  'pageOf': 'Página {page} de {total}',
  'total': 'Total',
  'status': 'Estado',
  'code': 'Código',
  'name': 'Nombre',
  'description': 'Descripción',
  'type': 'Tipo',
  'model': 'Modelo',
  'unit': 'Unidad',
  'quantity': 'Cantidad',
  'timestamp': 'Fecha y hora',
  'parameter': 'Parámetro',
  'active': 'Activo',
  'inactive': 'Inactivo',
  'normal': 'Normal',
  'startDate': 'Fecha de inicio',
  'endDate': 'Fecha de fin',
  'generalInformation': 'Información general',
  'updatedAt': 'Actualizado a las {time}',
  'calculatedAt': 'Calculado: {date}',
  'errorTitle': 'Algo salió mal',
  'errorNetwork': 'Sin conexión con QualiTrack. Verifica tu conexión a internet o la dirección de la API.',
  'errorTimeout': 'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
  'errorBadRequest': 'QualiTrack rechazó la solicitud.',
  'errorCredentialsRequired': 'Ingresa tu usuario y contraseña.',
  'errorUnauthorized': 'Tu sesión ya no es válida. Inicia sesión nuevamente.',
  'errorForbidden': 'No tienes acceso a esta información.',
  'errorOnboarding': 'La configuración de tu cuenta está incompleta. Complétala en QualiTrack Web.',
  'errorNotFound': 'No se encontró la información solicitada.',
  'errorConflict': 'La operación entra en conflicto con el estado actual.',
  'errorServer': 'QualiTrack no está disponible en este momento. Inténtalo más tarde.',
  'errorParsing': 'No se pudo interpretar la respuesta del servidor.',
  'errorMissingLaboratory': 'Tu cuenta no tiene un laboratorio asignado. Completa la configuración en QualiTrack Web.',
  'errorUnexpected': 'Ocurrió un error inesperado.',
  'checkingSession': 'Verificando sesión',
  'signInTitle': 'Iniciar sesión',
  'signInSubtitle': 'Bienvenido de nuevo a QualiTrack.',
  'username': 'Usuario',
  'usernameHint': 'nombre@empresa.com',
  'usernameRequired': 'El usuario es obligatorio',
  'password': 'Contraseña',
  'passwordHint': 'Tu contraseña',
  'passwordRequired': 'La contraseña es obligatoria',
  'showPassword': 'Mostrar contraseña',
  'hidePassword': 'Ocultar contraseña',
  'signIn': 'Iniciar sesión',
  'signingIn': 'Iniciando sesión',
  'invalidCredentials': 'Usuario o contraseña incorrectos.',
  'sessionExpired': 'Tu sesión expiró. Inicia sesión nuevamente.',
  'accountsManagedOnWeb': 'Las cuentas se crean y administran en QualiTrack Web.',
  'signOut': 'Cerrar sesión',
  'signOutConfirm': '¿Deseas cerrar sesión en QualiTrack?',
  'setupRequiredTitle': 'Completa tu configuración en QualiTrack Web',
  'setupSubscriptionMissing': 'Tu laboratorio aún no tiene una suscripción activa.',
  'setupLaboratoryMissing': 'Tu cuenta aún no está vinculada a un laboratorio.',
  'setupGeneric': 'La configuración de tu cuenta no está completa.',
  'setupRequiredHint': 'Las suscripciones, laboratorios y usuarios se configuran desde la aplicación web. Vuelve cuando esté listo.',
  'checkAgain': 'Verificar de nuevo',
  'roleAdmin': 'Administrador',
  'roleQaManager': 'QA Manager',
  'roleLabOperator': 'Operador de laboratorio',
  'navHome': 'Inicio',
  'navTelemetry': 'Telemetría',
  'navAlerts': 'Alertas',
  'navBatches': 'Lotes',
  'navMore': 'Más',
  'more': 'Más',
  'profile': 'Perfil',
  'about': 'Acerca de',
  'versionLabel': 'Versión {version}',
  'aboutDescription': 'QualiTrack Mobile es la app de monitoreo y revisión de la plataforma de gestión de calidad farmacéutica QualiTrack: telemetría, alertas de desviación, lotes de producción, inventario y facturación de un vistazo.',
  'aboutWebScope': 'La configuración y el registro de datos (laboratorios, productos, materiales, equipos, sensores, límites, lotes, usuarios y suscripciones) se realizan en QualiTrack Web.',
  'laboratory': 'Laboratorio',
  'laboratoryNumber': 'Laboratorio {id}',
  'ruc': 'RUC',
  'phone': 'Teléfono',
  'address': 'Dirección',
  'regulations': 'Normativas aplicables',
  'commandCenterTitle': 'Centro de Comando',
  'commandCenterSubtitle': 'Vista operativa del laboratorio, equipos, lotes, reportes y telemetría.',
  'welcomeUser': 'Hola, {name}',
  'keyOperationalMetrics': 'Métricas operativas clave',
  'openAlerts': 'Alertas abiertas',
  'rawMaterials': 'Materias primas',
  'operationalCount': '{count} operativos',
  'pendingInProgress': '{pending} pendientes · {inProgress} en progreso',
  'criticalCount': '{count} críticas',
  'lowStockCount': '{count} con stock bajo',
  'criticalAlertsCount': '{count} alertas críticas abiertas',
  'noCriticalAlerts': 'Sin alertas críticas abiertas',
  'liveTelemetry': 'Telemetría en vivo',
  'liveTelemetryHint': 'Última señal de monitoreo de equipos',
  'onlineOfTotal': '{online} de {total} equipos en línea',
  'onlineDevices': 'En línea',
  'telemetryAttention': 'Alertas de telemetría',
  'withoutStatus': 'Sin estado',
  'riskOverview': 'Resumen de riesgos',
  'riskOverviewHint': 'Elementos que pueden requerir atención operativa',
  'lowStock': 'Stock bajo',
  'kpisAtRisk': 'KPIs en riesgo',
  'itemsCount': '{count} elementos',
  'overallHealth': 'Salud general',
  'equipmentTitle': 'Equipos',
  'equipmentDetail': 'Detalle del equipo',
  'equipmentEmpty': 'Aún no se han registrado equipos en QualiTrack Web.',
  'equipmentSummary': '{total} registrados · {attention} requieren atención',
  'searchEquipment': 'Buscar por nombre, modelo o serie',
  'needsAttention': 'Requiere atención',
  'equipmentOperational': 'Operativo',
  'equipmentMaintenance': 'Mantenimiento',
  'equipmentOutOfService': 'Fuera de servicio',
  'equipment': 'Equipo',
  'equipmentNumber': 'Equipo #{id}',
  'serialNumber': 'N.° de serie',
  'linkedSensor': 'Sensor vinculado',
  'sensorLinked': 'Sensor vinculado',
  'noSensor': 'Sin sensor',
  'telemetryStatus': 'Estado de telemetría',
  'lastHeartbeat': 'Última señal',
  'viewTelemetry': 'Ver telemetría',
  'bpmLimits': 'Límites BPM',
  'bpmLimitsEmpty': 'No hay límites BPM configurados.',
  'maintenanceHistory': 'Historial de mantenimiento',
  'maintenanceEmpty': 'Sin registros de mantenimiento.',
  'deviationTrends': 'Tendencias de desviación',
  'dataPointsCount': '{count} puntos de datos',
  'trendIncreasing': 'En aumento',
  'trendDecreasing': 'En descenso',
  'trendStable': 'Estable',
  'complianceEvents': 'Eventos de cumplimiento',
  'auditLog': 'Registro de auditoría',
  'telemetryTitle': 'Panel de Telemetría',
  'telemetrySubtitle': 'Datos sensoriales y monitoreo de parámetros en tiempo real',
  'liveUpdates': 'En vivo · 15 s',
  'selectEquipment': 'Seleccionar equipo',
  'telemetryOperational': 'Operativo',
  'telemetryWarning': 'Advertencia',
  'telemetryCritical': 'Crítico',
  'telemetryOffline': 'Fuera de línea',
  'telemetryUnavailable': 'Telemetría no disponible',
  'online': 'En línea',
  'offline': 'Fuera de línea',
  'connectionStatus': 'Estado de conexión',
  'detectedAnomalies': 'Anomalías detectadas',
  'eventsCount': '{count} eventos',
  'anomaliesLast24h': 'Anomalías en las últimas 24 h',
  'liveTelemetryStream': 'Flujo de telemetría en vivo',
  'window15m': '15 min',
  'window1h': '1 h',
  'window6h': '6 h',
  'window24h': '24 h',
  'anomaly': 'Anomalía',
  'noHistoryInRange': 'Sin historial de telemetría para este rango',
  'chartSemantics': 'Gráfico de telemetría con {count} lecturas {unit}',
  'currentReadings': 'Lecturas actuales de sensores',
  'noMeasurements': 'Este equipo aún no ha reportado mediciones.',
  'targetRange': 'Objetivo: {min} – {max} {unit}',
  'withinLimits': 'Dentro de límites',
  'outOfLimits': 'Fuera de límites',
  'activeTelemetryEvents': 'Eventos de telemetría activos',
  'noAnomalies': 'No se detectaron anomalías.',
  'bpmDeviation': 'Desviación BPM',
  'rawTelemetryLog': 'Registro de telemetría',
  'rawTelemetrySubtitle': 'Registros sensoriales y desviaciones BPM',
  'dateRangeAll': 'Rango de fechas: todo',
  'onlyAnomalies': 'Solo anomalías',
  'liveEntries': 'Registros ({count})',
  'recordedValue': 'Valor registrado',
  'alertsTitle': 'Alertas de Cumplimiento',
  'alertsSubtitle': 'Alertas de desviación generadas por QualiTrack',
  'alertsEmptyTitle': 'Sin alertas de desviación',
  'alertsEmptyMessage': 'Todos los parámetros monitoreados están dentro de los límites.',
  'totalAlerts': 'Total de alertas',
  'criticalOpen': 'Críticas abiertas',
  'alertUnresolved': 'Sin resolver',
  'alertAcknowledged': 'Reconocida',
  'alertResolved': 'Resuelta',
  'severity': 'Severidad',
  'severityLow': 'Baja',
  'severityWarning': 'Advertencia',
  'severityCritical': 'Crítica',
  'alertNumber': 'Alerta #{id}',
  'batch': 'Lote',
  'batchNumberShort': 'Lote #{id}',
  'userNumber': 'Usuario #{id}',
  'deviationDetails': 'Detalle de desviación',
  'technicalInspection': 'Inspección técnica',
  'thresholdValue': 'Valor umbral',
  'acknowledgedBy': 'Reconocida por',
  'resolvedBy': 'Resuelta por',
  'resolutionNotes': 'Notas de resolución',
  'resolutionNotesHint': 'Describe la acción correctiva y su verificación',
  'resolutionNotesRequired': 'Las notas de resolución son obligatorias',
  'reviewActions': 'Acciones de revisión',
  'reviewRestricted': 'Las acciones de revisión están disponibles para QA Managers y Administradores.',
  'acknowledge': 'Reconocer',
  'acknowledgeAlert': 'Reconocer alerta',
  'acknowledgeConfirm': 'Confirma que revisaste esta desviación.',
  'markAsResolved': 'Marcar como resuelta',
  'resolveConfirm': 'La alerta se cerrará con tus notas de resolución.',
  'alertAcknowledgedMessage': 'Alerta reconocida',
  'alertResolvedMessage': 'Alerta resuelta',
  'batchesTitle': 'Lotes de Producción',
  'batchesSubtitle': 'Trazabilidad y control de calidad de los ciclos de producción',
  'batchesEmpty': 'Aún no se han registrado lotes de producción en QualiTrack Web.',
  'searchBatches': 'Buscar por número de lote o producto',
  'batchPending': 'Pendiente',
  'batchInProgress': 'En progreso',
  'batchReleased': 'Liberado',
  'batchRejected': 'Rechazado',
  'product': 'Producto',
  'awaitingQaRelease': 'En espera de liberación QA',
  'batchDetail': 'Detalle del lote',
  'rawMaterialsUsed': 'Materias primas usadas',
  'traceability': 'Trazabilidad',
  'bpmNotes': 'Notas BPM',
  'qaReview': 'Revisión QA',
  'qaReviewHint': 'Libera o rechaza este lote existente. QualiTrack valida la transición.',
  'releaseBatch': 'Liberar lote',
  'rejectBatch': 'Rechazar lote',
  'releaseDate': 'Fecha de liberación',
  'rejectionDate': 'Fecha de rechazo',
  'qualityReleaseNotes': 'Notas de liberación de calidad',
  'releaseNotesHint': 'Notas de liberación y observaciones de verificación',
  'releaseNotesRequired': 'Las notas de liberación son obligatorias',
  'rejectionReason': 'Motivo de rechazo',
  'rejectionReasonHint': 'Causa regulatoria o no conformidad BPM',
  'rejectionReasonRequired': 'El motivo de rechazo es obligatorio',
  'releaseConfirm': '¿Liberar el lote {batch}? Esta acción no se puede deshacer desde la app.',
  'rejectConfirm': '¿Rechazar el lote {batch}? Esta acción no se puede deshacer desde la app.',
  'batchReleasedMessage': 'Lote liberado',
  'batchRejectedMessage': 'Lote rechazado',
  'rawMaterialUsageHistory': 'Historial de uso de materias primas',
  'rawMaterialsUsedEmpty': 'Este lote no registra consumo de materias primas.',
  'materialNumber': 'Material #{id}',
  'stockBeforeAfter': 'Stock {before} → {after}',
  'receiptNumber': 'Recepción #{id}',
  'batchNoAlerts': 'No hay alertas de desviación para este lote.',
  'inventoryTitle': 'Inventario de Materias Primas',
  'inventoryEmpty': 'Aún no se han registrado materias primas en QualiTrack Web.',
  'materialsCount': '{count} materiales',
  'lowStockAlert': '{count} materiales están por debajo del stock mínimo',
  'searchMaterials': 'Buscar por nombre o código',
  'belowMinimum': 'Bajo el mínimo',
  'blockedStock': 'Stock bloqueado',
  'stockOk': 'Stock correcto',
  'usableStock': 'Stock utilizable',
  'physicalStock': 'Stock físico',
  'minimumStock': 'Stock mínimo',
  'materialDetail': 'Detalle del material',
  'receipts': 'Recepciones de proveedor',
  'receiptsEmpty': 'No hay recepciones registradas.',
  'supplier': 'Proveedor',
  'initialAmount': 'Cantidad inicial',
  'availableAmount': 'Cantidad disponible',
  'receivedOn': 'Recibido',
  'expiresOn': 'Vence',
  'usable': 'Utilizable',
  'receiptQuarantined': 'En cuarentena',
  'receiptReleased': 'Liberado',
  'receiptObserved': 'Observado',
  'receiptRejected': 'Rechazado',
  'movements': 'Movimientos de stock',
  'movementsEmpty': 'No hay movimientos registrados.',
  'productsTitle': 'Catálogo de Productos Farmacéuticos',
  'productsEmpty': 'Aún no se han registrado productos en QualiTrack Web.',
  'productsCount': '{count} productos registrados',
  'searchProducts': 'Buscar por código o nombre',
  'productDetail': 'Detalle del producto',
  'bpmSpecifications': 'Especificaciones BPM',
  'reportsTitle': 'Reportes y KPIs',
  'reportsSubtitle': 'Panel de KPIs y reportes generados',
  'reportsEmpty': 'Aún no se han generado KPIs ni reportes en QualiTrack Web.',
  'kpiDashboard': 'Panel de KPIs',
  'kpiEmpty': 'Aún no se ha calculado un panel de KPIs.',
  'kpiOnTrack': 'En objetivo',
  'kpiAtRisk': 'En riesgo',
  'targetValue': 'Objetivo: {value}',
  'reportHistory': 'Historial de reportes',
  'reportHistoryEmpty': 'No hay reportes generados.',
  'billingTitle': 'Resumen de Facturación',
  'billingSubtitle': 'Tu suscripción activa y el historial de pagos',
  'billingEmpty': 'No se encontraron suscripciones para este laboratorio.',
  'currentSubscription': 'Suscripción actual',
  'noActiveSubscription': 'Sin suscripción activa',
  'plan': 'Plan',
  'billingCycle': 'Ciclo de facturación',
  'periodStart': 'Inicio del periodo',
  'periodEnd': 'Fin del periodo',
  'amount': 'Monto',
  'maxUsers': 'Usuarios máximos',
  'maxEquipment': 'Equipos máximos',
  'paymentHistory': 'Historial de pagos',
  'paymentsEmpty': 'No hay pagos registrados.',
  'provider': 'Proveedor',
  'subscriptionHistory': 'Historial de suscripciones',
  'billingManagedOnWeb': 'Los cambios de plan, pagos y cancelaciones se gestionan en QualiTrack Web.',
};

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => const ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
