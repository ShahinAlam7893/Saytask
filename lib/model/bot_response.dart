// class BotResponse {
//   final String reply;
//   final bool isEvent;
//   final Map<String, dynamic>? eventData;

//   BotResponse({
//     required this.reply,
//     required this.isEvent,
//     this.eventData,
//   });

//   factory BotResponse.fromJson(Map<String, dynamic> json) {
//     return BotResponse(
//       reply: json["reply"] ?? "",
//       isEvent: json["is_event"] ?? false,
//       eventData: json["event_data"],
//     );
//   }
// }
