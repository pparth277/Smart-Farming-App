import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sfs/models/user.dart';
import 'package:sfs/services/database.dart';
import 'package:sfs/shared/loading.dart';

// const baseUrl = "http://192.168.43.114:5000";
const baseUrl = "http://54.209.180.202:5000";

User user;

class Vision extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(child: ImageCapture());
  }
}

class ImageCapture extends StatefulWidget {
  @override
  _ImageCaptureState createState() => _ImageCaptureState();
}

class _ImageCaptureState extends State<ImageCapture> {
  File _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    File selected = await ImagePicker.pickImage(source: source);
    setState(() {
      _imageFile = selected;
    });
  }

  void _clear() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _cropImage() async {
    File cropped = await ImageCropper.cropImage(sourcePath: _imageFile.path);
    setState(() {
      _imageFile = cropped ?? _imageFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<User>(context);
    return StreamBuilder<User>(
        stream: DatabaseService(farmerid: user.farmerId).userData,
        builder: (farmercontext, farmersnapshot) {
          if (farmersnapshot.hasData) {
            user = farmersnapshot.data;

            return SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(width: 30),
                      IconButton(
                        icon: Icon(Icons.photo_camera),
                        onPressed: () async {
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      SizedBox(width: 50),
                      IconButton(
                        icon: Icon(Icons.photo_library),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                      if (_imageFile != null) ...[
                        SizedBox(width: 40),
                        Row(children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.crop),
                            onPressed: _cropImage,
                          ),
                          SizedBox(width: 50),
                          IconButton(
                            icon: Icon(Icons.refresh),
                            onPressed: _clear,
                          ),
                        ]),
                      ]
                    ],
                  ),
                  if (_imageFile == null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 50,
                      ),
                      height: 250,
                      child: Center(
                        child: Text(
                          'Disease Detection based on leaves can be done here!',
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 50,
                      ),
                      height: 250,
                      child: Center(
                        child: Text(
                          'Please Capture leaf image or choose one form gallery',
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ],
                  if (_imageFile != null) ...[
                    Uploader(file: _imageFile),
                    SizedBox(
                      height: 10,
                    ),
                    Image.file(_imageFile),
                  ],
                ],
              ),
            );
          } else {
            return Loading();
          }
        });
  }
}

class Uploader extends StatefulWidget {
  final File file;

  Uploader({Key key, this.file}) : super(key: key);

  @override
  _UploaderState createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  String fileName;

  final FirebaseStorage _storage = FirebaseStorage(
      storageBucket: 'gs://smart-farm-system-94f3f.appspot.com');

  StorageUploadTask _uploadTask;

  void _startUpload(bool isUploadable, String name) {
    setState(() {
      fileName = name;
      if (isUploadable) {
        String filepath = 'farmers/${user.farmerId}/Leaves/${name}.jpg';
        _uploadTask = _storage.ref().child(filepath).putFile(widget.file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_uploadTask != null) {
      return StreamBuilder<StorageTaskEvent>(
        stream: _uploadTask.events,
        builder: (context, snapshot) {
          var event = snapshot?.data?.snapshot;

          double progressPercent =
              event != null ? event.bytesTransferred / event.totalByteCount : 0;

          return Column(children: [
            if (_uploadTask.isComplete)
              Center(
                child: Text(
                  fileName,
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ]);
        },
      );
    } else {
      return Center(
          child: FlatButton(
        child: Text(
          "Disease Scan",
          style: TextStyle(
              fontSize: 20,
              color: Colors.blueGrey[900],
              fontWeight: FontWeight.bold),
        ),
        color: Colors.green[300],
        onPressed: () async {
          final bytes = widget.file.readAsBytesSync();
          // print(bytes.toString().substring(0, 100));
          String img64 = base64Encode(bytes);
          // print(img64.substring(0, 100));

          try {
            var response = await http.post(baseUrl, body: img64);
            // print('Response status: ${response.statusCode}');
            // print('Response body: ${json.decode(response.body)['prediction']}');

            String name = json.decode(response.body)['prediction'];
            if (name != null) {
              print("--->>> ${name}");
              _startUpload(true, name);
            } else {
              print("--->>> ${name}");
              _startUpload(false, 'Server is not available');
            }
          } catch (e) {
            print('There is some Problem');
            _startUpload(false, DateTime.now().toString());
          }
        },
      ));
    }
  }
}
