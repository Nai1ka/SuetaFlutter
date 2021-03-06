import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_flutter/models/ChatMessage.dart';
import 'package:test_flutter/models/MethodResponse.dart';
import 'package:test_flutter/models/Event.dart';
import 'package:test_flutter/models/EventDescription.dart';

import 'package:test_flutter/ui/main/main_widget.dart';
import 'package:test_flutter/models/User.dart' as UserClass;

class Utils {
  static final Utils _singleton = Utils._internal();
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final firestore = FirebaseFirestore.instance;
  static final storage = FirebaseStorage.instance;
  static final eventsReference = FirebaseFirestore.instance
      .collection('core')
      .doc("events")
      .collection("list");
  static final userListReference = FirebaseFirestore.instance
      .collection("core")
      .doc("users")
      .collection("list");

  factory Utils() {
    return _singleton;
  }

  static Future<UserClass.User> getInfoAboutUser(String id) async {
    var rawUser = await firestore
        .collection("core")
        .doc("users")
        .collection("list")
        .doc(id)
        .get();
    if (rawUser.exists) {
      Map<String, dynamic> data = rawUser.data()!;
      var resultUser = UserClass.User(data["name"], data["age"], data["city"])
        ..friends = Map.castFrom(data["friends"])
        ..id = id;
      await getAvatarsURL(id).then((value) => resultUser.avatarURL = value);
      return resultUser;
    }
    throw "No such user";
    //TODO если пользоваель не существует(например, удалил аккаунт), то это сломается

    //var resultUser = User(rawUser.["name"], rawUser["name"], city, email)
  }

  static Future<List<UserClass.User>> getUsersFriendsProfiles(
      String userId) async {
    List<UserClass.User> resultList = [];
    Map<String, dynamic> friendsId = {};
    await FirebaseFirestore.instance
        .collection("core")
        .doc("users")
        .collection("list")
        .doc(userId)
        .get()
        .then((value) => friendsId = value.data()!["friends"]);
    for (var entry in friendsId.entries) {
      if (entry.value)
        await getInfoAboutUser(entry.key)
            .then((value) => resultList.add(value));
    }

    return resultList;
  }

  static Future<List<UserClass.User>> getUsersRequests(String userId) async {
    List<UserClass.User> resultList = [];
    List<dynamic> requestsId = [];
    await FirebaseFirestore.instance
        .collection("core")
        .doc("users")
        .collection("list")
        .doc(userId)
        .get()
        .then((value) => requestsId = value.data()!["friendRequests"]);
    for (var i in requestsId) {
      await getInfoAboutUser(i).then((value) => resultList.add(value));
    }

    return resultList;
  }

  static Future<List<Event>> getEventsFromSnapshot(
      AsyncSnapshot<QuerySnapshot> snapshot) async {
    List<Event> events = <Event>[];
    if (snapshot.hasData)
      for (int i = 0; i < snapshot.data!.docs.length; i++) {
        await getInfoAboutEvent(snapshot.data!.docs[i].id)
            .then((value) => events.add(value));
      }
    return events;
  }

  static Future<Event> getInfoAboutEvent(String id,
      [bool isAccepted = false]) async {
    var rawEvent = await firestore
        .collection("core")
        .doc("events")
        .collection("list")
        .doc(id)
        .get();
    if (rawEvent.exists) {
      var data = rawEvent.data()!;
      GeoPoint tempGeoPoint = data["eventPosition"]["geopoint"] as GeoPoint;
      var resultEvent = Event()
        ..eventName = data["eventName"]
        ..eventDescription = data["eventDescription"]
        ..eventPosition = LatLng(tempGeoPoint.latitude, tempGeoPoint.longitude)
        ..eventDate = (data["eventDate"] as Timestamp).toDate()
        ..eventOwnerId = data["eventOwner"]
        ..peopleNumber = data["peopleNumber"]
        ..id = id
        ..users = Map.castFrom(data["users"])
        ..isCurrentUserOwner = data['eventOwner'] == auth.currentUser!.uid
        ..isAccepted = isAccepted;
      await getEventImagesURLs(id)
          .then((value) => resultEvent.imageURLs = value);

      return resultEvent;
    }
    throw "Нет";
    //TODO если событие не существует(например, удалил аккаунт), то это сломается

    //var resultUser = User(rawUser.["name"], rawUser["name"], city, email)
  }

  static Future<List<Event>> getUsersOwnEvents(String userId) async {
    List<Event> resultList = [];
    List<dynamic> eventsId = [];
    await FirebaseFirestore.instance
        .collection("core")
        .doc("users")
        .collection("list")
        .doc(userId)
        .get()
        .then((value) => eventsId = value.data()!["ownEvents"]);
    for (var i in eventsId) {
      await getInfoAboutEvent(i).then((value) => resultList.add(value));
    }
    return resultList;
  }

  static Future<List<Event>> getUsersAvailableEvents(String userId) async {
    List<Event> resultList = [];
    Map<String, dynamic> requestsId = {};
    await FirebaseFirestore.instance
        .collection("core")
        .doc("users")
        .collection("list")
        .doc(userId)
        .get()
        .then((value) => requestsId = value.data()!["events"]);
    for (var i in requestsId.entries) {
      await getInfoAboutEvent(i.key, i.value)
          .then((value) => resultList.add(value));
    }
    return resultList;
  }

  static Future<List<UserClass.User>> getEventAcceptedGuests(
      Event event) async {
    List<UserClass.User> resultList = [];
    for (var i in event.users.entries) {
      if (i.value)
        await getInfoAboutUser(i.key).then((value) => resultList.add(value));
    }
    return resultList;
  }

  static Future<List<UserClass.User>> getEventNotAcceptedGuests(
      Event event) async {
    List<UserClass.User> resultList = [];
    for (var i in event.users.entries) {
      if (!i.value)
        await getInfoAboutUser(i.key).then((value) => resultList.add(value));
    }
    return resultList;
  }

  static String humanizeDate(DateTime? date) {
    var resultString = "";
    if (date != null) {
      resultString += date.day.toString();
      switch (date.month) {
        case 1:
          resultString += " января";
          break;
        case 2:
          resultString += " февраля";
          break;
        case 3:
          resultString += " марта";
          break;
        case 4:
          resultString += " апреля";
          break;
        case 5:
          resultString += " мая";
          break;
        case 6:
          resultString += " июня";
          break;
        case 7:
          resultString += " июля";
          break;
        case 8:
          resultString += " августа";
          break;
        case 9:
          resultString += " сентября";
          break;
        case 10:
          resultString += " октября";
          break;
        case 11:
          resultString += " ноября";
          break;
        case 12:
          resultString += " декабря";
          break;
        default:
          resultString += "";
          break;
      }
      /*resultString+=" в ";
      resultString+=date.hour.toString();
      resultString+=":";
      resultString+=date.minute.toString();*/
    }
    return resultString;
  }

  static getDateForDescription(DateTime date, bool isUserAccepted) {
    if (isUserAccepted)
      return "${humanizeDate(date)}, ${date.year} | ${date.hour}:${date.minute}";
    else
      return "${humanizeDate(date)}, ${date.year}";
  }

  static DateTime changeTime(DateTime dateTime, TimeOfDay timeOfDay) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, timeOfDay.hour,
        timeOfDay.minute);
  }

  static String formatDate(DateTime dateTime) {
    return "${dateTime.year} - ${dateTime.month} - ${dateTime.day}";
  }

  static checkEvent(Event event) {
    return event.eventName.length > 0 &&
        event.eventDescription.length > 0 &&
        event.peopleNumber > 0 &&
        event.eventPosition != null;
  }

  static saveEventToFirebase(Event event, List<File> imagesFiles) async {
    try {
      var docRef = await eventsReference.add({
        'eventDate': event.eventDate,
        'eventName': event.eventName,
        'eventDescription': event.eventDescription,
        'eventOwner': event.eventOwnerId,
        'eventPosition': geo
            .point(
                latitude: event.eventPosition!.latitude,
                longitude: event.eventPosition!.longitude)
            .data,
        'peopleNumber': event.peopleNumber,
        'users': {}
      });
      await userListReference.doc(auth.currentUser!.uid).update({
        "ownEvents": FieldValue.arrayUnion([docRef.id])
      });

      for (int i = 0; i < imagesFiles.length; i++) {
        await storage
            .ref('events/${docRef.id}/${imagesFiles[i].path.split('/').last}')
            .putFile(imagesFiles[i]);
      }
    } on FirebaseException catch (e) {
      // e.g, e.code == 'canceled'
    }
  }

  static deleteEvent(Event event) {
    try {
      eventsReference.doc(event.id).delete();
      event.users.forEach((key, value) {
        userListReference
            .doc(key)
            .update({"events.${event.id}": FieldValue.delete()});
      });
      userListReference.doc(event.eventOwnerId).update({
        "ownEvents": FieldValue.arrayRemove([event.id])
      });
      //TODO удалять данные и из storage

      return true;
    } catch (e) {
      return false;
    }
  }

  static addUserAsGuest(String eventID) {
    try {
      eventsReference.doc(eventID).set({
        "users": {auth.currentUser?.uid: false}
      }, SetOptions(merge: true));
      //Добавление данных в field users в документе events
      userListReference.doc(auth.currentUser!.uid).update({
        "events": {eventID: false}
      });
      //Добавление данных в field events в документе users (false, потому что гость - пользователь)
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool checkIfUserAlreadyRegisteredInEvent(Event event) {
    return event.users.containsKey(auth.currentUser!.uid) ||
        event.isCurrentUserOwner;
  }

  static Future<EventDescription> getEventDescription(String eventId) async {
    var event = await getInfoAboutEvent(eventId);
    var user = await getInfoAboutUser(event.eventOwnerId);

    return EventDescription(event, user);
  }

  static Future<MethodResponse> sendFriendsRequest(String friendId) async {
    try {
      var currentUser = await getInfoAboutUser(auth.currentUser!.uid);
      if (currentUser.friends.containsKey(friendId))
        return MethodResponse(true, "Этот пользователь уже у вас в друзьях");
      userListReference.doc(auth.currentUser!.uid).update({
        "friends": {friendId: false}
      });
      userListReference.doc(friendId).update({
        "friendRequests": FieldValue.arrayUnion([auth.currentUser!.uid])
      });
      return MethodResponse(false);
    } catch (e) {
      return MethodResponse(true, e.toString());
      //TODO сделать обработчик исключений, чтобы по-красоте всё было :)
    }
  }

  static changeAvatarImage(File file) async {
    try {
      await storage.ref('avatars/${auth.currentUser!.uid}.png').putFile(file);
    } on FirebaseException catch (e) {
      // e.g, e.code == 'canceled'
    }
  }

  static Future<String> getAvatarsURL(String userId) async {
    var downloadURL = "";
    try {
      downloadURL = await storage.ref('avatars/${userId}.png').getDownloadURL();
    } catch (e) {}
    return downloadURL;
  }

  static getAvatarWidget(String downloadURL, double radius) {
    if (downloadURL == "") {
      return CircleAvatar(radius: radius, child: Icon(Icons.person));
    } else {
      return CircleAvatar(
          radius: radius, backgroundImage: NetworkImage(downloadURL));
    }
  }

  static Future<List<String>> getEventImagesURLs(String eventId) async {
    List<String> eventImagesURLs = [];
    try {
      await storage
          .ref('events/${eventId}')
          .listAll()
          .then((imagesListRef) => imagesListRef.items.forEach((element) {
                element
                    .getDownloadURL()
                    .then((imageRef) => eventImagesURLs.add(imageRef));
              }));
    } catch (e) {}
    return eventImagesURLs;
  }


  static List<ChatMessage> getMessageList(List<QueryDocumentSnapshot> snapshots){
    List<ChatMessage> resultList  = [];
    for(int i =0;i<snapshots.length;i++){
      var _messageType = snapshots[i]["idFrom"]==auth.currentUser!.uid ? MessageTypes.sender : MessageTypes.receiver;
      resultList.add(ChatMessage(snapshots[i]["text"], _messageType));
    }
    return resultList;


  }

//var resultUser = User(rawUser.["name"], rawUser["name"], city, email)

  Utils._internal();
}
