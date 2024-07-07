import 'package:image_picker/image_picker.dart';

class HelperFunctions {
  final ImagePicker picker = ImagePicker();
  pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image;
  }
}
