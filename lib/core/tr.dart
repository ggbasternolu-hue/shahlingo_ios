/// A bilingual string. Russian is the default, English is optional.
class Tr {
  const Tr(this.ru, this.en);

  final String ru;
  final String en;

  String of(bool english) => english ? en : ru;
}
