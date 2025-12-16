// // lib/view/chat/chat_screen.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:saytask/model/chat_model.dart';
// import 'package:saytask/repository/calendar_service.dart';
// import 'package:saytask/repository/chat_service.dart';
// import 'package:saytask/repository/today_task_service.dart';
// import 'package:saytask/repository/notes_service.dart';
// import 'package:saytask/res/color.dart';
// import 'package:go_router/go_router.dart';

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<ChatViewModel>().fetchHistory();
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   Future<void> _sendMessage() async {
//     final message = _controller.text.trim();
//     if (message.isEmpty) return;

//     _controller.clear();
    
//     final chatViewModel = context.read<ChatViewModel>();
//     await chatViewModel.sendMessage(message);

//     // CRITICAL: Refresh providers after AI creates task/event/note
//     _refreshProviders();

//     _scrollToBottom();
//   }

//   void _refreshProviders() {
//     // Refresh all providers to show newly created items
//     context.read<CalendarProvider>().loadEvents();
//     context.read<TaskProvider>().loadTasks();
//     context.read<NotesProvider>().loadNotes();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.white,
//       appBar: AppBar(
//         backgroundColor: AppColors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => context.pop(),
//         ),
//         title: const Text(
//           'AI Assistant',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontFamily: 'Poppins',
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.black),
//             onPressed: () {
//               context.read<ChatViewModel>().fetchHistory();
//               _refreshProviders();
//             },
//           ),
//         ],
//       ),
//       body: Consumer<ChatViewModel>(
//         builder: (context, viewModel, child) {
//           if (viewModel.isLoading && viewModel.messages.isEmpty) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           return Column(
//             children: [
//               // Chat messages
//               Expanded(
//                 child: ListView.builder(
//                   controller: _scrollController,
//                   padding: EdgeInsets.all(16.w),
//                   itemCount: viewModel.messages.length,
//                   itemBuilder: (context, index) {
//                     final msg = viewModel.messages[index];
//                     return _buildMessageBubble(msg, viewModel);
//                   },
//                 ),
//               ),

//               // Loading indicator
//               if (viewModel.isLoading)
//                 Padding(
//                   padding: EdgeInsets.all(8.h),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       SizedBox(
//                         width: 16.w,
//                         height: 16.h,
//                         child: const CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                       SizedBox(width: 8.w),
//                       Text(
//                         'AI is thinking...',
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 12.sp,
//                           fontFamily: 'Poppins',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//               // Input area
//               Container(
//                 padding: EdgeInsets.all(12.w),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 10,
//                       offset: const Offset(0, -2),
//                     ),
//                   ],
//                 ),
//                 child: SafeArea(
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: _controller,
//                           decoration: InputDecoration(
//                             hintText: 'Ask AI to create task, event, or note...',
//                             hintStyle: TextStyle(
//                               color: Colors.grey[400],
//                               fontSize: 14.sp,
//                               fontFamily: 'Poppins',
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(24.r),
//                               borderSide: BorderSide(color: Colors.grey[300]!),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(24.r),
//                               borderSide: BorderSide(color: Colors.grey[300]!),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(24.r),
//                               borderSide: BorderSide(color: AppColors.green, width: 2),
//                             ),
//                             contentPadding: EdgeInsets.symmetric(
//                               horizontal: 16.w,
//                               vertical: 12.h,
//                             ),
//                           ),
//                           maxLines: null,
//                           textInputAction: TextInputAction.send,
//                           onSubmitted: (_) => _sendMessage(),
//                         ),
//                       ),
//                       SizedBox(width: 8.w),
//                       Container(
//                         decoration: BoxDecoration(
//                           color: AppColors.green,
//                           shape: BoxShape.circle,
//                         ),
//                         child: IconButton(
//                           icon: const Icon(Icons.send, color: Colors.white),
//                           onPressed: _sendMessage,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildMessageBubble(ChatMessage msg, ChatViewModel viewModel) {
//     final isUser = msg.type == MessageType.user;
    
//     return Align(
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: EdgeInsets.only(bottom: 12.h),
//         constraints: BoxConstraints(maxWidth: 280.w),
//         child: Column(
//           crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//           children: [
//             // Message bubble
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//               decoration: BoxDecoration(
//                 color: isUser ? AppColors.green : Colors.grey[200],
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(16.r),
//                   topRight: Radius.circular(16.r),
//                   bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
//                   bottomRight: Radius.circular(isUser ? 4.r : 16.r),
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Type badge for AI responses
//                   if (!isUser && msg.type != MessageType.bot) ...[
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//                       decoration: BoxDecoration(
//                         color: msg.type == MessageType.event 
//                             ? Colors.blue[100] 
//                             : msg.type == MessageType.task
//                                 ? Colors.orange[100]
//                                 : Colors.purple[100],
//                         borderRadius: BorderRadius.circular(8.r),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             msg.type == MessageType.event 
//                                 ? Icons.event 
//                                 : msg.type == MessageType.task
//                                     ? Icons.task_alt
//                                     : Icons.note,
//                             size: 14.sp,
//                             color: msg.type == MessageType.event 
//                                 ? Colors.blue[700] 
//                                 : msg.type == MessageType.task
//                                     ? Colors.orange[700]
//                                     : Colors.purple[700],
//                           ),
//                           SizedBox(width: 4.w),
//                           Text(
//                             '${msg.type.name.toUpperCase()} CREATED',
//                             style: TextStyle(
//                               fontSize: 10.sp,
//                               fontWeight: FontWeight.bold,
//                               color: msg.type == MessageType.event 
//                                   ? Colors.blue[700] 
//                                   : msg.type == MessageType.task
//                                       ? Colors.orange[700]
//                                       : Colors.purple[700],
//                               fontFamily: 'Poppins',
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(height: 8.h),
//                   ],

//                   // Message text
//                   Text(
//                     msg.message,
//                     style: TextStyle(
//                       color: isUser ? Colors.white : Colors.black87,
//                       fontSize: 14.sp,
//                       fontFamily: 'Poppins',
//                     ),
//                   ),

//                   // Event/Task details
//                   if (!isUser && msg.eventTime != null) ...[
//                     SizedBox(height: 8.h),
//                     Row(
//                       children: [
//                         Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]),
//                         SizedBox(width: 4.w),
//                         Text(
//                           DateFormat('MMM d, h:mm a').format(msg.eventTime!),
//                           style: TextStyle(
//                             fontSize: 12.sp,
//                             color: Colors.grey[600],
//                             fontFamily: 'Poppins',
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),

//             // Timestamp
//             if (msg.createdAt != null) ...[
//               SizedBox(height: 4.h),
//               Text(
//                 DateFormat('h:mm a').format(msg.createdAt!),
//                 style: TextStyle(
//                   fontSize: 10.sp,
//                   color: Colors.grey[500],
//                   fontFamily: 'Poppins',
//                 ),
//               ),
//             ],

//             // Action buttons for AI-created items
//             if (!isUser && (msg.type == MessageType.event || msg.type == MessageType.task)) ...[
//               SizedBox(height: 8.h),
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildActionButton(
//                     icon: Icons.visibility,
//                     label: 'View',
//                     onPressed: () {
//                       if (msg.type == MessageType.event) {
//                         context.push('/calendar');
//                       } else if (msg.type == MessageType.task) {
//                         context.push('/today');
//                       }
//                     },
//                   ),
//                   SizedBox(width: 8.w),
//                   _buildActionButton(
//                     icon: Icons.delete_outline,
//                     label: 'Remove',
//                     color: Colors.red,
//                     onPressed: () => viewModel.deleteMessage(msg),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onPressed,
//     Color? color,
//   }) {
//     return InkWell(
//       onTap: onPressed,
//       borderRadius: BorderRadius.circular(8.r),
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//         decoration: BoxDecoration(
//           color: Colors.grey[100],
//           borderRadius: BorderRadius.circular(8.r),
//           border: Border.all(color: Colors.grey[300]!),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 14.sp, color: color ?? Colors.grey[700]),
//             SizedBox(width: 4.w),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 11.sp,
//                 color: color ?? Colors.grey[700],
//                 fontWeight: FontWeight.w600,
//                 fontFamily: 'Poppins',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }