part of flutter_parse_sdk;

class ParseUser extends ParseBase {
  ParseHTTPClient _client;
  static final String className = '_User';
  String path = "/classes/$className";
  bool _debug;

  String acl;
  String username;
  String password;
  String emailAddress;

  /// Creates an instance of ParseUser
  ///
  /// Users can set whether debug should be set on this class with a [bool],
  /// they can also create thier own custom version of [ParseHttpClient]
  ///
  /// Creates a new user locally
  ///
  /// Requires [String] username, [String] password. [String] email address
  /// is required as well to create a full new user object on ParseServer. Only
  /// username and password is required to login
  ParseUser(this.username, this.password, this.emailAddress,
      {bool debug, ParseHTTPClient client})
      : super() {
    client == null ? _client = ParseHTTPClient() : _client = client;
    _debug = isDebugEnabled(client, objectLevelDebug: debug);
  }

  /// Returns a [User] from a [Map] object
  fromJson(objectData) {
    if (getObjectData() == null) {
      setObjectData(objectData);
    } else {
      getObjectData().addAll(objectData);
    }

    objectId = getObjectData()[OBJECT_ID];
    createdAt = stringToDateTime(getObjectData()[CREATED_AT]);
    updatedAt = stringToDateTime(getObjectData()[UPDATED_AT]);
    acl = getObjectData()[ACL].toString();
    username = getObjectData()[USERNAME];
    password = getObjectData()[PASSWORD];
    emailAddress = getObjectData()[EMAIL];

    if (updatedAt == null) updatedAt = createdAt;

    saveInStorage(PARSE_STORE_USER);

    return getObjectData();
  }

  /// Returns a [String] that's human readable. Ideal for printing logs
  @override
  String toString() => "Username: $username \nEmail Address:$emailAddress";

  static const String USERNAME = 'Username';
  static const String EMAIL = 'Email';
  static const String PASSWORD = 'Password';
  static const String ACL = 'ACL';

  create(String username, String password, [String emailAddress]) {
    return ParseUser(username, password, emailAddress);
  }

  /// Gets the current user from the server
  ///
  /// Current user is stored locally, but in case of a server update [bool]
  /// fromServer can be called and an updated version of the [User] object will be
  /// returned
  getCurrentUserFromServer() async {
    // We can't get the current user and session without a sessionId
    if (_client.data.sessionId == null) return null;

    try {
      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri uri = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}/users/me");

      final response = await _client
          .get(uri, headers: {HEADER_SESSION_TOKEN: _client.data.sessionId});
      return _handleResponse(response, ParseApiRQ.currentUser);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.currentUser);
    }
  }
  /// Gets the current user from storage
  ///
  /// Current user is stored locally, but in case of a server update [bool]
  /// fromServer can be called and an updated version of the [User] object will be
  /// returned
  static currentUser() {
    return _getUserFromLocalStore();
  }

  /// Registers a user on Parse Server
  ///
  /// After creating a new user via [Parse.create] call this method to register
  /// that user on Parse
  signUp() async {
    try {
      if (emailAddress == null) return null;

      Map<String, dynamic> bodyData = {};
      bodyData["email"] = emailAddress;
      bodyData["password"] = password;
      bodyData["username"] = username;

      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$path");

      final response = await _client.post(url,
          headers: {
            HEADER_REVOCABLE_SESSION: "1",
          },
          body: JsonEncoder().convert(bodyData));

      _handleResponse(response, ParseApiRQ.signUp);
      return this;
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.signUp);
    }
  }

  /// Logs a user in via Parse
  ///
  /// Once a user is created using [Parse.create] and a username and password is
  /// provided, call this method to login.
  login() async {
    try {
      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}/login",
          queryParameters: {"username": username, "password": password});

      final response = await _client.post(url, headers: {
        HEADER_REVOCABLE_SESSION: "1",
      });

      _handleResponse(response, ParseApiRQ.login);
      return this;
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.login);
    }
  }

  /// Removes the current user from the session data
  logout() {
    _client.data.sessionId = null;
    setObjectData(null);
  }

  /// Sends a verification email to the users email address
  verificationEmailRequest() async {
    try {
      final response = await _client.post(
          "${_client.data.serverUrl}/verificationEmailRequest",
          body: JsonEncoder().convert({"email": emailAddress}));

      return _handleResponse(response, ParseApiRQ.verificationEmailRequest);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.verificationEmailRequest);
    }
  }

  /// Sends a password reset email to the users email address
  requestPasswordReset() async {
    try {
      final response = await _client.post(
          "${_client.data.serverUrl}/requestPasswordReset",
          body: JsonEncoder().convert({"email": emailAddress}));

      return _handleResponse(response, ParseApiRQ.requestPasswordReset);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.requestPasswordReset);
    }
  }

  /// Saves the current user
  ///
  /// If changes are made to the current user, call save to sync them with
  /// Parse Server
  save() async {
    if (objectId == null) {
      return signUp();
    } else {
      try {
        final response = await _client.put(
            _client.data.serverUrl + "$path/$objectId",
            body: JsonEncoder().convert(getObjectData()));
        return _handleResponse(response, ParseApiRQ.save);
      } on Exception catch (e) {
        return _handleException(e, ParseApiRQ.save);
      }
    }
  }

  /// Removes a user from Parse Server locally and online
  destroy() async {
    if (objectId != null) {
      try {
        final response = await _client.delete(
            _client.data.serverUrl + "$path/$objectId",
            headers: {"X-Parse-Session-Token": _client.data.sessionId});
        _handleResponse(response, ParseApiRQ.destroy);
        return objectId;
      } on Exception catch (e) {
        return _handleException(e, ParseApiRQ.destroy);
      }
    }
  }

  /// Gets a list of all users (limited return)
  all() async {
    try {
      final response = await _client.get(_client.data.serverUrl + "$path");
      return _handleResponse(response, ParseApiRQ.all);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.all);
    }
  }

  static _getUserFromLocalStore() {
    var userJson = ParseCoreData().getStore().getString(PARSE_STORE_USER);

    if (userJson != null) {
      var userMap = JsonDecoder().convert(userJson);

      if (userMap != null) {
        ParseCoreData().sessionId = userMap['sessionToken'];

        var user = ParseUser(
            userMap['username'],
            userMap['password'],
            userMap['emailAddress']);

        user.fromJson(userMap);
        return user;
      }
    }

    return null;
  }

  /// Handles an API response and logs data if [bool] debug is enabled
  @protected
  ParseResponse _handleException(Exception exception, ParseApiRQ type) {
    ParseResponse parseResponse = ParseResponse.handleException(this, exception);

    if (_debug) {
      logger(ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    return parseResponse;
  }

  /// Handles all the response data for this class
  _handleResponse(Response response, ParseApiRQ type) {
    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);
    if (responseData.containsKey('sessionToken')) {
      fromJson(responseData);
      _client.data.sessionId = responseData['sessionToken'];
    }

    ParseResponse parseResponse = ParseResponse.handleResponse(this, response);
    if (_debug) {
      logger(ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    return this;
  }
}