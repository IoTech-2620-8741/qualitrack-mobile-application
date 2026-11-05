/// `EnvironmentUsage` of the backend: what an environment is used for.
enum EnvironmentUsage {
  laboratory('LABORATORY'),
  production('PRODUCTION'),
  rawMaterialStorage('RAW_MATERIAL_STORAGE'),
  productStorage('PRODUCT_STORAGE'),
  other('OTHER'),
  unassigned('');

  const EnvironmentUsage(this.code);

  final String code;

  static EnvironmentUsage fromCode(String? code) {
    for (final value in values) {
      if (value != unassigned && value.code == code) return value;
    }
    return EnvironmentUsage.unassigned;
  }
}
