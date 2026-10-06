// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: l10n/strings.tsv — regenerate with `dart run tool/generate_l10n.dart`.

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
  String get startDate => _t('startDate');
  String get endDate => _t('endDate');
  String get generalInformation => _t('generalInformation');
  String updatedAt(String time) => _t('updatedAt')
      .replaceAll('{time}', time);
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
      .replaceAll('{version}', version);
  String get aboutDescription => _t('aboutDescription');
  String get aboutWebScope => _t('aboutWebScope');
  String get laboratory => _t('laboratory');
  String get ruc => _t('ruc');
  String get phone => _t('phone');
  String get address => _t('address');
  String get regulations => _t('regulations');
  String welcomeUser(String name) => _t('welcomeUser')
      .replaceAll('{name}', name);
  String get keyOperationalMetrics => _t('keyOperationalMetrics');
  String get openAlerts => _t('openAlerts');
  String operationalCount(int count) => _t('operationalCount')
      .replaceAll('{count}', '$count');
  String criticalCount(int count) => _t('criticalCount')
      .replaceAll('{count}', '$count');
  String criticalAlertsCount(int count) => _t('criticalAlertsCount')
      .replaceAll('{count}', '$count');
  String get noCriticalAlerts => _t('noCriticalAlerts');
  String get liveTelemetry => _t('liveTelemetry');
  String get liveTelemetryHint => _t('liveTelemetryHint');
  String get lowStock => _t('lowStock');
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
  String equipmentNumber(int id) => _t('equipmentNumber')
      .replaceAll('{id}', '$id');
  String get serialNumber => _t('serialNumber');
  String get viewTelemetry => _t('viewTelemetry');
  String get bpmLimits => _t('bpmLimits');
  String get bpmLimitsEmpty => _t('bpmLimitsEmpty');
  String get maintenanceHistory => _t('maintenanceHistory');
  String get maintenanceEmpty => _t('maintenanceEmpty');
  String get complianceEvents => _t('complianceEvents');
  String get auditLog => _t('auditLog');
  String get telemetryTitle => _t('telemetryTitle');
  String get telemetrySubtitle => _t('telemetrySubtitle');
  String get liveUpdates => _t('liveUpdates');
  String get telemetryUnavailable => _t('telemetryUnavailable');
  String get connectionStatus => _t('connectionStatus');
  String eventsCount(int count) => _t('eventsCount')
      .replaceAll('{count}', '$count');
  String get liveTelemetryStream => _t('liveTelemetryStream');
  String get window15m => _t('window15m');
  String get window1h => _t('window1h');
  String get window6h => _t('window6h');
  String get window24h => _t('window24h');
  String get noHistoryInRange => _t('noHistoryInRange');
  String chartSemantics(int count, String unit) => _t('chartSemantics')
      .replaceAll('{count}', '$count')
      .replaceAll('{unit}', unit);
  String get currentReadings => _t('currentReadings');
  String get rawTelemetryLog => _t('rawTelemetryLog');
  String get rawTelemetrySubtitle => _t('rawTelemetrySubtitle');
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
      .replaceAll('{batch}', batch);
  String rejectConfirm(String batch) => _t('rejectConfirm')
      .replaceAll('{batch}', batch);
  String get batchReleasedMessage => _t('batchReleasedMessage');
  String get batchRejectedMessage => _t('batchRejectedMessage');
  String get rawMaterialsUsedEmpty => _t('rawMaterialsUsedEmpty');
  String materialNumber(int id) => _t('materialNumber')
      .replaceAll('{id}', '$id');
  String stockBeforeAfter(String before, String after) => _t('stockBeforeAfter')
      .replaceAll('{before}', before)
      .replaceAll('{after}', after);
  String receiptNumber(int id) => _t('receiptNumber')
      .replaceAll('{id}', '$id');
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
  String get account => _t('account');
  String get actionCoolingOff => _t('actionCoolingOff');
  String get actionCoolingOn => _t('actionCoolingOn');
  String get actionExecuted => _t('actionExecuted');
  String get actionFailed => _t('actionFailed');
  String get actionServoClose => _t('actionServoClose');
  String get actionServoOpen => _t('actionServoOpen');
  String get actionVentilationOff => _t('actionVentilationOff');
  String get actionVentilationOn => _t('actionVentilationOn');
  String get addPhoto => _t('addPhoto');
  String get alertsOpen => _t('alertsOpen');
  String get anEnvironment => _t('anEnvironment');
  String get auditorReadOnly => _t('auditorReadOnly');
  String get automaticActions => _t('automaticActions');
  String get automaticActionsHint => _t('automaticActionsHint');
  String get batchesInProgress => _t('batchesInProgress');
  String get batchesThatUsedIt => _t('batchesThatUsedIt');
  String get changePassword => _t('changePassword');
  String get changePasswordForcedHint => _t('changePasswordForcedHint');
  String get changePasswordTitle => _t('changePasswordTitle');
  String get changePhoto => _t('changePhoto');
  String conditionNormalized(String date) => _t('conditionNormalized')
      .replaceAll('{date}', date);
  String get confirmPassword => _t('confirmPassword');
  String get connected => _t('connected');
  String connectedOfTotal(int connected, int total) => _t('connectedOfTotal')
      .replaceAll('{connected}', '$connected')
      .replaceAll('{total}', '$total');
  String get container => _t('container');
  String get containerMonitor => _t('containerMonitor');
  String get criticalRange => _t('criticalRange');
  String criticalRangeValue(String range) => _t('criticalRangeValue')
      .replaceAll('{range}', range);
  String get currentPassword => _t('currentPassword');
  String get deviationIndicators => _t('deviationIndicators');
  String get deviationIndicators7d => _t('deviationIndicators7d');
  String get deviations24h => _t('deviations24h');
  String deviationsCount(int count) => _t('deviationsCount')
      .replaceAll('{count}', '$count');
  String get deviationsHint => _t('deviationsHint');
  String get deviationsLabel => _t('deviationsLabel');
  String deviationsSummary(int deviations, int critical) => _t('deviationsSummary')
      .replaceAll('{deviations}', '$deviations')
      .replaceAll('{critical}', '$critical');
  String get deviceIdentifier => _t('deviceIdentifier');
  String get digitalSignature => _t('digitalSignature');
  String get dni => _t('dni');
  String get dniInvalid => _t('dniInvalid');
  String get edit => _t('edit');
  String get email => _t('email');
  String get emailNotifications => _t('emailNotifications');
  String get emailNotificationsHint => _t('emailNotificationsHint');
  String get environment => _t('environment');
  String get environmentalDevice => _t('environmentalDevice');
  String get equipmentUsed => _t('equipmentUsed');
  String get firmware => _t('firmware');
  String get firstDetected => _t('firstDetected');
  String get fullName => _t('fullName');
  String get fullNameInvalid => _t('fullNameInvalid');
  String get history => _t('history');
  String get inAppNotifications => _t('inAppNotifications');
  String get inAppNotificationsHint => _t('inAppNotificationsHint');
  String get iotDevices => _t('iotDevices');
  String get iotRole => _t('iotRole');
  String get lastCommunication => _t('lastCommunication');
  String get location => _t('location');
  String get locationInvalid => _t('locationInvalid');
  String get lotDepleted => _t('lotDepleted');
  String get lotExpired => _t('lotExpired');
  String get lotNearExpiry => _t('lotNearExpiry');
  String get lotNotYetReceived => _t('lotNotYetReceived');
  String get markAllRead => _t('markAllRead');
  String get materialLots => _t('materialLots');
  String get measurementSummary => _t('measurementSummary');
  String get metricAirQuality => _t('metricAirQuality');
  String get metricHumidity => _t('metricHumidity');
  String get metricLuminosity => _t('metricLuminosity');
  String get metricMotion => _t('metricMotion');
  String get metricRfidTag => _t('metricRfidTag');
  String get metricTemperature => _t('metricTemperature');
  String minMax(String min, String max) => _t('minMax')
      .replaceAll('{min}', min)
      .replaceAll('{max}', max);
  String get minimumSeverity => _t('minimumSeverity');
  String get minimumSeverityHint => _t('minimumSeverityHint');
  String get motionDetected => _t('motionDetected');
  String get movementConsumption => _t('movementConsumption');
  String get movementReceipt => _t('movementReceipt');
  String get movementReview => _t('movementReview');
  String get movementStorage => _t('movementStorage');
  String get neverCommunicated => _t('neverCommunicated');
  String get newPassword => _t('newPassword');
  String get noAutomaticActions => _t('noAutomaticActions');
  String get noBatchesUsedIt => _t('noBatchesUsedIt');
  String get noContainerAssigned => _t('noContainerAssigned');
  String get noDeviations => _t('noDeviations');
  String get noEquipmentUsed => _t('noEquipmentUsed');
  String get noOpenAlerts => _t('noOpenAlerts');
  String get noParticipatingStaff => _t('noParticipatingStaff');
  String get noProfileConfigured => _t('noProfileConfigured');
  String get noReadings24h => _t('noReadings24h');
  String get noReadingsInPeriod => _t('noReadingsInPeriod');
  String get normalRange => _t('normalRange');
  String normalRangeValue(String range) => _t('normalRangeValue')
      .replaceAll('{range}', range);
  String get notEvaluated => _t('notEvaluated');
  String get notLocated => _t('notLocated');
  String noticeAlertAcknowledged(String actor, String variable, String environment) => _t('noticeAlertAcknowledged')
      .replaceAll('{actor}', actor)
      .replaceAll('{variable}', variable)
      .replaceAll('{environment}', environment);
  String noticeAlertEscalated(String variable, String environment, String level, String value, String unit) => _t('noticeAlertEscalated')
      .replaceAll('{variable}', variable)
      .replaceAll('{environment}', environment)
      .replaceAll('{level}', level)
      .replaceAll('{value}', value)
      .replaceAll('{unit}', unit);
  String noticeAlertOpened(String severity, String environment, String variable, String value, String unit) => _t('noticeAlertOpened')
      .replaceAll('{severity}', severity)
      .replaceAll('{environment}', environment)
      .replaceAll('{variable}', variable)
      .replaceAll('{value}', value)
      .replaceAll('{unit}', unit);
  String noticeAlertResolved(String actor, String variable, String environment) => _t('noticeAlertResolved')
      .replaceAll('{actor}', actor)
      .replaceAll('{variable}', variable)
      .replaceAll('{environment}', environment);
  String noticeBatchRejected(String actor, String batch, String note) => _t('noticeBatchRejected')
      .replaceAll('{actor}', actor)
      .replaceAll('{batch}', batch)
      .replaceAll('{note}', note);
  String noticeBatchReleased(String actor, String batch) => _t('noticeBatchReleased')
      .replaceAll('{actor}', actor)
      .replaceAll('{batch}', batch);
  String get noticeLevelCritical => _t('noticeLevelCritical');
  String get noticeLevelLow => _t('noticeLevelLow');
  String get noticeLevelWarning => _t('noticeLevelWarning');
  String get noticeSeverityCritical => _t('noticeSeverityCritical');
  String get noticeSeverityLow => _t('noticeSeverityLow');
  String get noticeSeverityWarning => _t('noticeSeverityWarning');
  String get notificationPreferences => _t('notificationPreferences');
  String get notificationsEmpty => _t('notificationsEmpty');
  String get notificationsTitle => _t('notificationsTitle');
  String notificationsUnread(int count) => _t('notificationsUnread')
      .replaceAll('{count}', '$count');
  String get onlyDeviations => _t('onlyDeviations');
  String get openAlertsHint => _t('openAlertsHint');
  String get participatingStaff => _t('participatingStaff');
  String get passwordChanged => _t('passwordChanged');
  String get passwordPolicyHint => _t('passwordPolicyHint');
  String get passwordsDoNotMatch => _t('passwordsDoNotMatch');
  String pendingCount(int count) => _t('pendingCount')
      .replaceAll('{count}', '$count');
  String get period24h => _t('period24h');
  String get period31d => _t('period31d');
  String get period7d => _t('period7d');
  String get periodMax31Days => _t('periodMax31Days');
  String get personalData => _t('personalData');
  String get phoneInvalid => _t('phoneInvalid');
  String get photoRemoved => _t('photoRemoved');
  String get photoTooLarge => _t('photoTooLarge');
  String get photoTypeNotAllowed => _t('photoTypeNotAllowed');
  String get photoUpdated => _t('photoUpdated');
  String get preferencesSaved => _t('preferencesSaved');
  String get profileSaved => _t('profileSaved');
  String profileVersion(String version) => _t('profileVersion')
      .replaceAll('{version}', version);
  String readingsCount(int count) => _t('readingsCount')
      .replaceAll('{count}', '$count');
  String get recentBatches => _t('recentBatches');
  String get removePhoto => _t('removePhoto');
  String get removePhotoConfirm => _t('removePhotoConfirm');
  String renewalCancelled(String date) => _t('renewalCancelled')
      .replaceAll('{date}', date);
  String get reportBatchTraceability => _t('reportBatchTraceability');
  String get reportCompliance => _t('reportCompliance');
  String get reportEquipmentLog => _t('reportEquipmentLog');
  String get reportInventory => _t('reportInventory');
  String get reportKpiSummary => _t('reportKpiSummary');
  String get reportsGeneratedOnWeb => _t('reportsGeneratedOnWeb');
  String get requiresReview => _t('requiresReview');
  String get roleAuditor => _t('roleAuditor');
  String get save => _t('save');
  String get selectDevice => _t('selectDevice');
  String get signatureHash => _t('signatureHash');
  String get signedAt => _t('signedAt');
  String get signedBy => _t('signedBy');
  String get someone => _t('someone');
  String get stateCritical => _t('stateCritical');
  String get stateNormal => _t('stateNormal');
  String get stateWarning => _t('stateWarning');
  String get telemetryNoDevices => _t('telemetryNoDevices');
  String thresholdExceeded(String value) => _t('thresholdExceeded')
      .replaceAll('{value}', value);
  String timeInRange(String value) => _t('timeInRange')
      .replaceAll('{value}', value);
  String get unread => _t('unread');
  String until(String date) => _t('until')
      .replaceAll('{date}', date);
  String get viewAll => _t('viewAll');
  String get you => _t('you');
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
  'startDate': 'Start date',
  'endDate': 'End date',
  'generalInformation': 'General information',
  'updatedAt': 'Updated at {time}',
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
  'ruc': 'RUC',
  'phone': 'Phone',
  'address': 'Address',
  'regulations': 'Applicable regulations',
  'welcomeUser': 'Hello, {name}',
  'keyOperationalMetrics': 'Key operational metrics',
  'openAlerts': 'Open alerts',
  'operationalCount': '{count} operational',
  'criticalCount': '{count} critical',
  'criticalAlertsCount': '{count} critical alerts open',
  'noCriticalAlerts': 'No critical alerts open',
  'liveTelemetry': 'Live telemetry',
  'liveTelemetryHint': 'Readings of the last 24 hours',
  'lowStock': 'Low stock',
  'equipmentTitle': 'Equipment',
  'equipmentDetail': 'Equipment detail',
  'equipmentEmpty': 'No equipment has been registered in QualiTrack Web yet.',
  'equipmentSummary': '{total} registered · {attention} need attention',
  'searchEquipment': 'Search by name, model or serial',
  'needsAttention': 'Needs attention',
  'equipmentOperational': 'Operational',
  'equipmentMaintenance': 'Maintenance',
  'equipmentOutOfService': 'Out of service',
  'equipmentNumber': 'Equipment #{id}',
  'serialNumber': 'Serial number',
  'viewTelemetry': 'View telemetry',
  'bpmLimits': 'BPM limits',
  'bpmLimitsEmpty': 'No BPM limits configured.',
  'maintenanceHistory': 'Maintenance history',
  'maintenanceEmpty': 'No maintenance records.',
  'complianceEvents': 'Compliance events',
  'auditLog': 'Audit log',
  'telemetryTitle': 'Telemetry Dashboard',
  'telemetrySubtitle': 'Real-time sensory data and parameter monitoring',
  'liveUpdates': 'Live · 15 s',
  'telemetryUnavailable': 'Telemetry unavailable',
  'connectionStatus': 'Connection status',
  'eventsCount': '{count} events',
  'liveTelemetryStream': 'Live telemetry stream',
  'window15m': '15 min',
  'window1h': '1 h',
  'window6h': '6 h',
  'window24h': '24 h',
  'noHistoryInRange': 'No telemetry history for this range',
  'chartSemantics': 'Telemetry chart with {count} readings {unit}',
  'currentReadings': 'Current sensor readings',
  'rawTelemetryLog': 'Raw telemetry data log',
  'rawTelemetrySubtitle': 'Sensory logs and BPM deviation records',
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
  'reviewRestricted': 'Only the quality manager releases or rejects batches.',
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
  'rawMaterialsUsedEmpty': 'No raw materials were consumed by this batch.',
  'materialNumber': 'Material #{id}',
  'stockBeforeAfter': 'Stock {before} → {after}',
  'receiptNumber': 'Receipt #{id}',
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
  'account': 'Account',
  'actionCoolingOff': 'Cooling off',
  'actionCoolingOn': 'Cooling on',
  'actionExecuted': 'Executed',
  'actionFailed': 'Failed',
  'actionServoClose': 'Servo closed',
  'actionServoOpen': 'Servo opened',
  'actionVentilationOff': 'Ventilation off',
  'actionVentilationOn': 'Ventilation on',
  'addPhoto': 'Add photo',
  'alertsOpen': 'Open',
  'anEnvironment': 'an environment',
  'auditorReadOnly': 'Auditors consult alerts without changing them.',
  'automaticActions': 'Automatic actions',
  'automaticActionsHint': 'Responses of the container in the last 24 hours',
  'batchesInProgress': 'Batches in progress',
  'batchesThatUsedIt': 'Batches that used it',
  'changePassword': 'Change password',
  'changePasswordForcedHint': 'You signed in with a temporary password. Choose your own password to continue.',
  'changePasswordTitle': 'Choose your password',
  'changePhoto': 'Change photo',
  'conditionNormalized': 'The condition returned to normal on {date}; the alert stays open until someone resolves it.',
  'confirmPassword': 'Confirm the new password',
  'connected': 'Connected',
  'connectedOfTotal': '{connected} of {total} devices connected',
  'container': 'Container',
  'containerMonitor': 'Container monitor',
  'criticalRange': 'Critical range',
  'criticalRangeValue': 'critical {range}',
  'currentPassword': 'Current password',
  'deviationIndicators': 'Deviation indicators',
  'deviationIndicators7d': 'Deviation indicators (7 days)',
  'deviations24h': 'Deviations (24 h)',
  'deviationsCount': '{count} deviations',
  'deviationsHint': 'Readings evaluated as warning or critical',
  'deviationsLabel': 'Deviations',
  'deviationsSummary': '{deviations} deviations · {critical} critical',
  'deviceIdentifier': 'Device identifier',
  'digitalSignature': 'Digital signature',
  'dni': 'DNI',
  'dniInvalid': 'The DNI must have 8 digits.',
  'edit': 'Edit',
  'email': 'E-mail',
  'emailNotifications': 'E-mail',
  'emailNotificationsHint': 'Receive alerts that reach the minimum severity by e-mail',
  'environment': 'Environment',
  'environmentalDevice': 'Environmental device',
  'equipmentUsed': 'Equipment used',
  'firmware': 'Firmware',
  'firstDetected': 'First detected',
  'fullName': 'Full name',
  'fullNameInvalid': 'Enter between 2 and 120 characters.',
  'history': 'History',
  'inAppNotifications': 'In the app',
  'inAppNotificationsHint': 'Show notices in the bell',
  'iotDevices': 'IoT devices',
  'iotRole': 'IoT role',
  'lastCommunication': 'Last communication',
  'location': 'Location',
  'locationInvalid': 'Enter between 2 and 120 characters.',
  'lotDepleted': 'Depleted',
  'lotExpired': 'Expired',
  'lotNearExpiry': 'Near expiry',
  'lotNotYetReceived': 'Not received yet',
  'markAllRead': 'Mark all as read',
  'materialLots': 'Lots',
  'measurementSummary': 'Measurement summary',
  'metricAirQuality': 'Air quality',
  'metricHumidity': 'Humidity',
  'metricLuminosity': 'Luminosity',
  'metricMotion': 'Motion',
  'metricRfidTag': 'RFID tag',
  'metricTemperature': 'Temperature',
  'minMax': 'min {min} · max {max}',
  'minimumSeverity': 'Minimum severity',
  'minimumSeverityHint': 'Alerts below this severity do not notify you. Batch notices always arrive.',
  'motionDetected': 'Detected',
  'movementConsumption': 'Consumption',
  'movementReceipt': 'Receipt',
  'movementReview': 'Review',
  'movementStorage': 'Storage',
  'neverCommunicated': 'Never',
  'newPassword': 'New password',
  'noAutomaticActions': 'No automatic actions in the last 24 hours.',
  'noBatchesUsedIt': 'No batch has used this material.',
  'noContainerAssigned': 'The batch has no container assigned.',
  'noDeviations': 'No deviations in the last 24 hours.',
  'noEquipmentUsed': 'No equipment registered for this batch.',
  'noOpenAlerts': 'There are no open alerts.',
  'noParticipatingStaff': 'No staff registered for this batch.',
  'noProfileConfigured': 'No ranges configured yet',
  'noReadings24h': 'The device sent no readings in the last 24 hours.',
  'noReadingsInPeriod': 'There are no readings in the period.',
  'normalRange': 'Normal range',
  'normalRangeValue': 'normal {range}',
  'notEvaluated': 'Not evaluated',
  'notLocated': 'Not located',
  'noticeAlertAcknowledged': '{actor} is attending the alert of {variable} in {environment}.',
  'noticeAlertEscalated': 'The alert of {variable} in {environment} rose to {level}: {value} {unit}.',
  'noticeAlertOpened': 'New {severity} alert in {environment}: {variable} at {value} {unit}.',
  'noticeAlertResolved': '{actor} resolved the alert of {variable} in {environment}.',
  'noticeBatchRejected': '{actor} rejected batch {batch}: {note}',
  'noticeBatchReleased': '{actor} released batch {batch}.',
  'noticeLevelCritical': 'critical',
  'noticeLevelLow': 'low',
  'noticeLevelWarning': 'warning',
  'noticeSeverityCritical': 'critical',
  'noticeSeverityLow': 'low',
  'noticeSeverityWarning': 'warning',
  'notificationPreferences': 'Notification preferences',
  'notificationsEmpty': 'You have no notifications yet.',
  'notificationsTitle': 'Notifications',
  'notificationsUnread': 'Notifications, {count} unread',
  'onlyDeviations': 'Only deviations',
  'openAlertsHint': 'Most urgent first',
  'participatingStaff': 'Participating staff',
  'passwordChanged': 'Your password was changed.',
  'passwordPolicyHint': 'Between 8 and 72 characters, with letters and numbers.',
  'passwordsDoNotMatch': 'The passwords do not match.',
  'pendingCount': '{count} pending',
  'period24h': '24 hours',
  'period31d': '31 days',
  'period7d': '7 days',
  'periodMax31Days': 'Choose a period of up to 31 days',
  'personalData': 'Personal data',
  'phoneInvalid': 'Enter a phone with 6 to 15 digits.',
  'photoRemoved': 'Your photo was removed.',
  'photoTooLarge': 'The photo cannot exceed 2 MB.',
  'photoTypeNotAllowed': 'Choose a JPG, PNG or WebP image.',
  'photoUpdated': 'Your photo was updated.',
  'preferencesSaved': 'Preferences saved.',
  'profileSaved': 'Your data was saved.',
  'profileVersion': 'Profile version {version}',
  'readingsCount': '{count} readings',
  'recentBatches': 'Recent batches',
  'removePhoto': 'Remove photo',
  'removePhotoConfirm': 'Your initials will be shown instead of the photo.',
  'renewalCancelled': 'Renewal cancelled: access until {date}',
  'reportBatchTraceability': 'Batch traceability',
  'reportCompliance': 'Environmental compliance',
  'reportEquipmentLog': 'Equipment log',
  'reportInventory': 'Inventory',
  'reportKpiSummary': 'Indicator summary',
  'reportsGeneratedOnWeb': 'Reports are generated and downloaded in QualiTrack Web.',
  'requiresReview': 'Requires review',
  'roleAuditor': 'Auditor',
  'save': 'Save',
  'selectDevice': 'Device',
  'signatureHash': 'SHA-256 hash',
  'signedAt': 'Signed at',
  'signedBy': 'Signed by',
  'someone': 'Someone',
  'stateCritical': 'Critical',
  'stateNormal': 'Normal',
  'stateWarning': 'Warning',
  'telemetryNoDevices': 'There are no IoT devices located in an environment yet.',
  'thresholdExceeded': 'Limit exceeded: {value}',
  'timeInRange': '{value} in range',
  'unread': 'Unread',
  'until': 'until {date}',
  'viewAll': 'View all',
  'you': 'You',
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
  'startDate': 'Fecha de inicio',
  'endDate': 'Fecha de fin',
  'generalInformation': 'Información general',
  'updatedAt': 'Actualizado a las {time}',
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
  'roleQaManager': 'Responsable de calidad',
  'roleLabOperator': 'Operario',
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
  'ruc': 'RUC',
  'phone': 'Teléfono',
  'address': 'Dirección',
  'regulations': 'Normativas aplicables',
  'welcomeUser': 'Hola, {name}',
  'keyOperationalMetrics': 'Métricas operativas clave',
  'openAlerts': 'Alertas abiertas',
  'operationalCount': '{count} operativos',
  'criticalCount': '{count} críticas',
  'criticalAlertsCount': '{count} alertas críticas abiertas',
  'noCriticalAlerts': 'Sin alertas críticas abiertas',
  'liveTelemetry': 'Telemetría en vivo',
  'liveTelemetryHint': 'Lecturas de las últimas 24 horas',
  'lowStock': 'Stock bajo',
  'equipmentTitle': 'Equipos',
  'equipmentDetail': 'Detalle del equipo',
  'equipmentEmpty': 'Aún no se han registrado equipos en QualiTrack Web.',
  'equipmentSummary': '{total} registrados · {attention} requieren atención',
  'searchEquipment': 'Buscar por nombre, modelo o serie',
  'needsAttention': 'Requiere atención',
  'equipmentOperational': 'Operativo',
  'equipmentMaintenance': 'Mantenimiento',
  'equipmentOutOfService': 'Fuera de servicio',
  'equipmentNumber': 'Equipo #{id}',
  'serialNumber': 'N.° de serie',
  'viewTelemetry': 'Ver telemetría',
  'bpmLimits': 'Límites BPM',
  'bpmLimitsEmpty': 'No hay límites BPM configurados.',
  'maintenanceHistory': 'Historial de mantenimiento',
  'maintenanceEmpty': 'Sin registros de mantenimiento.',
  'complianceEvents': 'Eventos de cumplimiento',
  'auditLog': 'Registro de auditoría',
  'telemetryTitle': 'Panel de Telemetría',
  'telemetrySubtitle': 'Datos sensoriales y monitoreo de parámetros en tiempo real',
  'liveUpdates': 'En vivo · 15 s',
  'telemetryUnavailable': 'Telemetría no disponible',
  'connectionStatus': 'Estado de conexión',
  'eventsCount': '{count} eventos',
  'liveTelemetryStream': 'Flujo de telemetría en vivo',
  'window15m': '15 min',
  'window1h': '1 h',
  'window6h': '6 h',
  'window24h': '24 h',
  'noHistoryInRange': 'Sin historial de telemetría para este rango',
  'chartSemantics': 'Gráfico de telemetría con {count} lecturas {unit}',
  'currentReadings': 'Lecturas actuales de sensores',
  'rawTelemetryLog': 'Registro de telemetría',
  'rawTelemetrySubtitle': 'Registros sensoriales y desviaciones BPM',
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
  'reviewRestricted': 'Solo el responsable de calidad libera o rechaza lotes.',
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
  'rawMaterialsUsedEmpty': 'Este lote no registra consumo de materias primas.',
  'materialNumber': 'Material #{id}',
  'stockBeforeAfter': 'Stock {before} → {after}',
  'receiptNumber': 'Recepción #{id}',
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
  'account': 'Cuenta',
  'actionCoolingOff': 'Refrigeración apagada',
  'actionCoolingOn': 'Refrigeración encendida',
  'actionExecuted': 'Ejecutada',
  'actionFailed': 'Fallida',
  'actionServoClose': 'Servo cerrado',
  'actionServoOpen': 'Servo abierto',
  'actionVentilationOff': 'Ventilación apagada',
  'actionVentilationOn': 'Ventilación encendida',
  'addPhoto': 'Agregar foto',
  'alertsOpen': 'Abiertas',
  'anEnvironment': 'un ambiente',
  'auditorReadOnly': 'Los auditores consultan las alertas sin modificarlas.',
  'automaticActions': 'Acciones automáticas',
  'automaticActionsHint': 'Respuestas del contenedor en las últimas 24 horas',
  'batchesInProgress': 'Lotes en proceso',
  'batchesThatUsedIt': 'Lotes que la usaron',
  'changePassword': 'Cambiar contraseña',
  'changePasswordForcedHint': 'Ingresaste con una contraseña temporal. Elige tu propia contraseña para continuar.',
  'changePasswordTitle': 'Elige tu contraseña',
  'changePhoto': 'Cambiar foto',
  'conditionNormalized': 'La condición volvió a la normalidad el {date}; la alerta sigue abierta hasta que alguien la resuelva.',
  'confirmPassword': 'Confirma la nueva contraseña',
  'connected': 'Conectado',
  'connectedOfTotal': '{connected} de {total} dispositivos conectados',
  'container': 'Contenedor',
  'containerMonitor': 'Monitor de contenedor',
  'criticalRange': 'Rango crítico',
  'criticalRangeValue': 'crítico {range}',
  'currentPassword': 'Contraseña actual',
  'deviationIndicators': 'Indicadores de desviaciones',
  'deviationIndicators7d': 'Indicadores de desviaciones (7 días)',
  'deviations24h': 'Desviaciones (24 h)',
  'deviationsCount': '{count} desviaciones',
  'deviationsHint': 'Lecturas evaluadas como advertencia o críticas',
  'deviationsLabel': 'Desviaciones',
  'deviationsSummary': '{deviations} desviaciones · {critical} críticas',
  'deviceIdentifier': 'Identificador del dispositivo',
  'digitalSignature': 'Firma digital',
  'dni': 'DNI',
  'dniInvalid': 'El DNI debe tener 8 dígitos.',
  'edit': 'Editar',
  'email': 'Correo',
  'emailNotifications': 'Correo',
  'emailNotificationsHint': 'Recibir por correo las alertas que alcancen la severidad mínima',
  'environment': 'Ambiente',
  'environmentalDevice': 'Dispositivo ambiental',
  'equipmentUsed': 'Equipos usados',
  'firmware': 'Firmware',
  'firstDetected': 'Primera detección',
  'fullName': 'Nombre completo',
  'fullNameInvalid': 'Ingresa entre 2 y 120 caracteres.',
  'history': 'Historial',
  'inAppNotifications': 'En la aplicación',
  'inAppNotificationsHint': 'Mostrar los avisos en la campanita',
  'iotDevices': 'Dispositivos IoT',
  'iotRole': 'Rol IoT',
  'lastCommunication': 'Última comunicación',
  'location': 'Ubicación',
  'locationInvalid': 'Ingresa entre 2 y 120 caracteres.',
  'lotDepleted': 'Agotado',
  'lotExpired': 'Vencido',
  'lotNearExpiry': 'Próximo a vencer',
  'lotNotYetReceived': 'Aún no recibido',
  'markAllRead': 'Marcar todas como leídas',
  'materialLots': 'Lotes',
  'measurementSummary': 'Resumen de mediciones',
  'metricAirQuality': 'Calidad del aire',
  'metricHumidity': 'Humedad',
  'metricLuminosity': 'Luminosidad',
  'metricMotion': 'Movimiento',
  'metricRfidTag': 'Etiqueta RFID',
  'metricTemperature': 'Temperatura',
  'minMax': 'mín {min} · máx {max}',
  'minimumSeverity': 'Severidad mínima',
  'minimumSeverityHint': 'Las alertas por debajo de esta severidad no te avisan. Los avisos de lotes siempre llegan.',
  'motionDetected': 'Detectado',
  'movementConsumption': 'Consumo',
  'movementReceipt': 'Recepción',
  'movementReview': 'Revisión',
  'movementStorage': 'Almacenamiento',
  'neverCommunicated': 'Nunca',
  'newPassword': 'Nueva contraseña',
  'noAutomaticActions': 'Sin acciones automáticas en las últimas 24 horas.',
  'noBatchesUsedIt': 'Ningún lote ha usado este material.',
  'noContainerAssigned': 'El lote no tiene contenedor asignado.',
  'noDeviations': 'Sin desviaciones en las últimas 24 horas.',
  'noEquipmentUsed': 'No hay equipos registrados para este lote.',
  'noOpenAlerts': 'No hay alertas abiertas.',
  'noParticipatingStaff': 'No hay personal registrado para este lote.',
  'noProfileConfigured': 'Aún no hay rangos configurados',
  'noReadings24h': 'El dispositivo no envió lecturas en las últimas 24 horas.',
  'noReadingsInPeriod': 'No hay lecturas en el periodo.',
  'normalRange': 'Rango normal',
  'normalRangeValue': 'normal {range}',
  'notEvaluated': 'Sin evaluar',
  'notLocated': 'Sin ubicar',
  'noticeAlertAcknowledged': '{actor} está atendiendo la alerta de {variable} en {environment}.',
  'noticeAlertEscalated': 'La alerta de {variable} en {environment} pasó a {level}: {value} {unit}.',
  'noticeAlertOpened': 'Nueva alerta {severity} en {environment}: {variable} en {value} {unit}.',
  'noticeAlertResolved': '{actor} resolvió la alerta de {variable} en {environment}.',
  'noticeBatchRejected': '{actor} rechazó el lote {batch}: {note}',
  'noticeBatchReleased': '{actor} liberó el lote {batch}.',
  'noticeLevelCritical': 'crítica',
  'noticeLevelLow': 'leve',
  'noticeLevelWarning': 'advertencia',
  'noticeSeverityCritical': 'crítica',
  'noticeSeverityLow': 'leve',
  'noticeSeverityWarning': 'de advertencia',
  'notificationPreferences': 'Preferencias de notificación',
  'notificationsEmpty': 'Aún no tienes notificaciones.',
  'notificationsTitle': 'Notificaciones',
  'notificationsUnread': 'Notificaciones, {count} sin leer',
  'onlyDeviations': 'Solo desviaciones',
  'openAlertsHint': 'Las más urgentes primero',
  'participatingStaff': 'Personal participante',
  'passwordChanged': 'Tu contraseña se cambió.',
  'passwordPolicyHint': 'Entre 8 y 72 caracteres, con letras y números.',
  'passwordsDoNotMatch': 'Las contraseñas no coinciden.',
  'pendingCount': '{count} pendientes',
  'period24h': '24 horas',
  'period31d': '31 días',
  'period7d': '7 días',
  'periodMax31Days': 'Elige un periodo de hasta 31 días',
  'personalData': 'Datos personales',
  'phoneInvalid': 'Ingresa un teléfono de 6 a 15 dígitos.',
  'photoRemoved': 'Se quitó tu foto.',
  'photoTooLarge': 'La foto no puede superar 2 MB.',
  'photoTypeNotAllowed': 'Elige una imagen JPG, PNG o WebP.',
  'photoUpdated': 'Se actualizó tu foto.',
  'preferencesSaved': 'Preferencias guardadas.',
  'profileSaved': 'Se guardaron tus datos.',
  'profileVersion': 'Perfil versión {version}',
  'readingsCount': '{count} lecturas',
  'recentBatches': 'Lotes recientes',
  'removePhoto': 'Quitar foto',
  'removePhotoConfirm': 'Se mostrarán tus iniciales en lugar de la foto.',
  'renewalCancelled': 'Renovación cancelada: acceso hasta el {date}',
  'reportBatchTraceability': 'Trazabilidad de lote',
  'reportCompliance': 'Cumplimiento ambiental',
  'reportEquipmentLog': 'Bitácora de equipo',
  'reportInventory': 'Inventario',
  'reportKpiSummary': 'Resumen de indicadores',
  'reportsGeneratedOnWeb': 'Los reportes se generan y descargan en QualiTrack Web.',
  'requiresReview': 'Requiere revisión',
  'roleAuditor': 'Auditor',
  'save': 'Guardar',
  'selectDevice': 'Dispositivo',
  'signatureHash': 'Huella SHA-256',
  'signedAt': 'Firmado el',
  'signedBy': 'Firmado por',
  'someone': 'Alguien',
  'stateCritical': 'Crítico',
  'stateNormal': 'Normal',
  'stateWarning': 'Advertencia',
  'telemetryNoDevices': 'Aún no hay dispositivos IoT ubicados en un ambiente.',
  'thresholdExceeded': 'Límite superado: {value}',
  'timeInRange': '{value} en rango',
  'unread': 'Sin leer',
  'until': 'hasta el {date}',
  'viewAll': 'Ver todas',
  'you': 'Tú',
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
