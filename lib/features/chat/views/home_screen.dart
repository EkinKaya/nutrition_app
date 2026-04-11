import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/chat_messages_list.dart';
import '../widgets/chat_input_area.dart';
import '../chat_provider.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final ChatProvider _chatProvider = ChatProvider();

  // PageView tab değiştiğinde bu sayfayı bellekte tut
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _chatProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için zorunlu
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: HomeAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ChatMessagesList(provider: _chatProvider),
          ),
          ChatInputArea(provider: _chatProvider),
        ],
      ),
    );
  }
}
