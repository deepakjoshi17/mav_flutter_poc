class Utils {

  static String getNameInitials(String? name) {

    if (name == null || name.isEmpty) {
      return "NA";
    }
    final initials = name.split(" ").map((e) => e[0]).take(2).join().toUpperCase();
    return initials;
  }
}