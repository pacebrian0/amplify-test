import 'dart:async';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_test/models/Blog.dart';
import 'package:amplify_test/models/Post.dart';
import 'package:flutter/material.dart';

class BlogScreen extends StatefulWidget {
  @override
  _BlogScreenState createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  late StreamSubscription _subscription;

  List<Blog> _blogs = [];
  String _blogTitle = "";
  String _postTitle = "";

  bool _loggedIn = false;
  bool _registered = false;

  String _email = "pacebrian0@gmail.com";
  String _password = "12345678";
  String _confirmationNumber = "";

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
  }

  // @override
  // void initState() {
  //   super.initState();
  //
  //
  //   _subscription = Amplify.DataStore.observe(Blog.classType)
  //       .listen((SubscriptionEvent event) {
  //     print(event.eventType);
  //     switch (event.eventType) {
  //       case EventType.create:
  //         _blogs.add(event.item);
  //         break;
  //       case EventType.update:
  //         var index = _blogs.indexOf(event.item);
  //         _blogs[index] = event.item;
  //         break;
  //       case EventType.delete:
  //         _blogs.removeWhere((element) => element.id == event.item.id);
  //         break;
  //     }
  //     setState(() {});
  //   });
  //   initBlogs();
  // }

  @override
  void initState() {
    super.initState();
    // Stream<GraphQLResponse<Blog>> subscribe() {
    //   final subscriptionRequest = ModelSubscriptions.onCreate(Blog.classType);
    //   final Stream<GraphQLResponse> operation = Amplify.API
    //       .subscribe(
    //     subscriptionRequest,
    //     onEstablished: () => print('Subscription established'),
    //   )
    //   // Listens to only 5 elements
    //       .take(5)
    //       .handleError(
    //         (error) {
    //       print('Error in subscription stream: $error');
    //     },
    //   );
    //   return operation;
    // }
    //
    _subscription = Amplify.DataStore.observe(Blog.classType)
        .listen((SubscriptionEvent<Blog> event) {
      print(event.eventType);
      switch (event.eventType) {
        case EventType.create:
          _blogs.add(event.item);
          break;
        case EventType.update:
          var index = _blogs.indexOf(event.item);
          _blogs[index] = event.item;
          break;
        case EventType.delete:
          _blogs.removeWhere((element) => element.id == event.item.id);
          break;
      }
      setState(() {});
    });
    initBlogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Our Blogs")),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  separatorBuilder: (context, index) => Divider(
                    indent: 16,
                    endIndent: 16,
                    color: Colors.black,
                  ),
                  itemCount: _blogs.length,
                  itemBuilder: (item, index) {
                    return ListTile(
                      title: Text(_blogs[index].name),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () async {
                          Amplify.DataStore.delete(_blogs[index]);
                        },
                      ),
                      onTap: () async {
                        // TODO: Query for the Posts and navigate to it
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: _loggedIn
                        ? Column(children: [
                            Text(
                              "Add a new Blog Post",
                              style: TextStyle(fontSize: 22),
                            ),
                            TextFormField(
                              decoration:
                                  InputDecoration(labelText: "Blog Title"),
                              onChanged: (value) {
                                _blogTitle = value;
                              },
                            ),
                            TextFormField(
                              decoration:
                                  InputDecoration(labelText: "Post Title"),
                              onChanged: (value) {
                                _postTitle = value;
                              },
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              child: Text("Add Blog"),
                              onPressed: () async {
                                var blog = Blog(name: _blogTitle);
                                var post = Post(title: _postTitle, blog: blog);
                                Amplify.DataStore.save(blog);
                                Amplify.DataStore.save(post);
                              },
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await Amplify.Auth.signOut();
                                setState(() {
                                  _loggedIn = false;
                                });
                              },
                              child: Text("Logout"),
                            )
                          ])
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Please log into your account to add new blogs",
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _login,
                                child: Text("Log in"),
                              ),
                              Divider(
                                color: Colors.black,
                                indent: 8,
                                endIndent: 8,
                              ),
                              ElevatedButton(
                                onPressed: _registerAccount,
                                child: Text("Register"),
                              ),
                              TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _confirmationNumber = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: "Confirmation Code",
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _registered &&
                                        _confirmationNumber.isNotEmpty
                                    ? _confirmSignUp
                                    : null,
                                child: Text("Confirmation"),
                              )
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  void _login() async {
    SignInResult res = await Amplify.Auth.signIn(username: _email, password: _password);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Logged In successful"),
    ));

    setState(() {_loggedIn = res.isSignedIn;});
  }

  void _registerAccount() async {
    await Amplify.Auth.signUp(
        username: _email,
        password: _password,
        options: CognitoSignUpOptions(
          userAttributes: {CognitoUserAttributeKey.email: _email},
        ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Registration complete"),
    ));
    setState(() {
      _registered = true;
    });
  }

  _confirmSignUp() async {
    SignUpResult res = await Amplify.Auth.confirmSignUp(
        username: _email, confirmationCode: _confirmationNumber);
    if (res.isSignUpComplete) {
      _login();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Confirmation complete"),
      ));
    }
  }

  Future<void> initBlogs() async {
    _blogs = await Amplify.DataStore.query(Blog.classType);
  }
}
