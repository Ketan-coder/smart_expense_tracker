class ProfileScope {
  ProfileScope._();

  static String activeProfileId = 'default';

  static String boxName(String legacyName) =>
      boxNameForProfile(activeProfileId, legacyName);

  static String boxNameForProfile(String profileId, String legacyName) =>
      profileId == 'default' ? legacyName : '${legacyName}__profile_$profileId';
}
