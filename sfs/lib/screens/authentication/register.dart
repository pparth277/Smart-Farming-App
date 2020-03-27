import 'package:flutter/material.dart';
import 'package:sfs/services/authService.dart';
import 'package:sfs/shared/constant.dart';
import 'package:sfs/shared/loading.dart';
import 'package:google_fonts/google_fonts.dart';

class Register extends StatefulWidget {
  final Function toggleView;
  Register({this.toggleView});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.green[100],
            appBar: AppBar(
              backgroundColor: Colors.green[400],
              //  elevation: 0.0,
              title: Text("Sign Up"),
            ),
            body: SingleChildScrollView(
              child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 50,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 20.0),
                        RichText(
                            text: TextSpan(
                                text: 'SFS',
                                style: GoogleFonts.lobster(
                                    fontSize: 100, color: Colors.brown[400]))),
                        SizedBox(height: 40.0),
                        TextFormField(
                          decoration:
                              textInputDecoration.copyWith(hintText: 'Email'),
                          validator: (val) =>
                              val.isEmpty ? 'Enter a email' : null,
                          onChanged: (val) {
                            setState(() => email = val);
                          },
                        ),
                        SizedBox(height: 20.0),
                        TextFormField(
                          decoration: textInputDecoration.copyWith(
                              hintText: 'Password'),
                          validator: (val) => val.length < 6
                              ? 'Enter a password atleast 6 character long'
                              : null,
                          obscureText: true,
                          onChanged: (val) {
                            setState(() => password = val);
                          },
                        ),
                        SizedBox(height: 20.0),
                        SizedBox(
                          height: 40,
                          width: double.infinity,
                          child: RaisedButton(
                            color: Colors.green[400],
                            child: Text(
                              'Sign Up',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState.validate()) {
                                setState(() {
                                  loading = true;
                                });
                                dynamic result =
                                    await _auth.registerWithEmailAndPassword(
                                        email, password);
                                if (result == null) {
                                  setState(() =>
                                      error = 'Please supply a valid data');
                                  loading = false;
                                }
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          error,
                          style: TextStyle(color: Colors.red, fontSize: 14.0),
                        ),
                        SizedBox(height: 145),
                        SizedBox(
                          height: 40,
                          width: double.infinity,
                          child: RaisedButton(
                              color: Colors.green[300],
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 17),
                              ),
                              onPressed: widget.toggleView),
                        ),
                      ],
                    ),
                  )),
            ),
          );
  }
}