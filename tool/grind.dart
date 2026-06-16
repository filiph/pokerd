import 'package:cli_pkg/cli_pkg.dart' as pkg;
import 'package:grinder/grinder.dart';

void main(List<String> args) {
  pkg.name.value = "pokerd";
  pkg.githubRepo.value = "filiph/pokerd";
  pkg.homebrewRepo.value = "filiph/homebrew-tap";
  
  pkg.addAllTasks();
  grind(args);
}
