// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_CN locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh_CN';

  static String m0(bytes) => "(已下载${bytes})";

  static String m1(phase, reason) => "失败阶段：${phase}\\n原因：${reason}";

  static String m2(project) => "已删除 ${project}";

  static String m3(count) => "正在排队 (还有 ${count} 人)";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("关于"),
    "add": MessageLookupByLibrary.simpleMessage("添加"),
    "addAudio": MessageLookupByLibrary.simpleMessage("添加曲目"),
    "addLanguage": MessageLookupByLibrary.simpleMessage("添加语言"),
    "addLanguageHint": MessageLookupByLibrary.simpleMessage(
      "可以添加辅助内容，比如音标、罗马音或拼音等",
    ),
    "adjustLyricOffset": MessageLookupByLibrary.simpleMessage("调整歌词延迟"),
    "apply": MessageLookupByLibrary.simpleMessage("申请"),
    "attachToLyric": MessageLookupByLibrary.simpleMessage("位置吸附到歌词"),
    "audioPathInvalidHint": MessageLookupByLibrary.simpleMessage(
      "请输入本地音频文件路径或有效的 YouTube 链接",
    ),
    "autoFillMetadata": MessageLookupByLibrary.simpleMessage("补全音乐信息"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "clearLyric": MessageLookupByLibrary.simpleMessage("清除歌词"),
    "confirm": MessageLookupByLibrary.simpleMessage("确定"),
    "continuePracticing": MessageLookupByLibrary.simpleMessage("继续"),
    "copyCurrentLyric": MessageLookupByLibrary.simpleMessage("复制当前歌词"),
    "copyWholeLyric": MessageLookupByLibrary.simpleMessage("复制全部歌词"),
    "copyright2026": MessageLookupByLibrary.simpleMessage(
      "版权所有 © 2026 Joodo。根据 GPLv3 许可证授权。",
    ),
    "createNewProject": MessageLookupByLibrary.simpleMessage("新建项目"),
    "currentLyricCopyed": MessageLookupByLibrary.simpleMessage("已复制当前歌词"),
    "dark": MessageLookupByLibrary.simpleMessage("深色"),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "downloadedBytes": m0,
    "downloadingStatus": MessageLookupByLibrary.simpleMessage("正在下载"),
    "editLyric": MessageLookupByLibrary.simpleMessage("编辑歌词"),
    "editTranslateLyric": MessageLookupByLibrary.simpleMessage("编辑歌词翻译"),
    "failed": MessageLookupByLibrary.simpleMessage("失败"),
    "failedToLoad": MessageLookupByLibrary.simpleMessage("加载错误"),
    "failedToReadAloudPleaseRetry": MessageLookupByLibrary.simpleMessage(
      "获取语音失败，请重试",
    ),
    "failureOfTest": MessageLookupByLibrary.simpleMessage("失败："),
    "followSystem": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "functionOfAcoustID": MessageLookupByLibrary.simpleMessage("用于补全音乐信息"),
    "functionOfLlm": MessageLookupByLibrary.simpleMessage("用于理解和翻译歌词"),
    "functionOfMvsep": MessageLookupByLibrary.simpleMessage("用于生成伴奏"),
    "initiatingService": MessageLookupByLibrary.simpleMessage("正在初始化服务"),
    "interface": MessageLookupByLibrary.simpleMessage("界面"),
    "language": MessageLookupByLibrary.simpleMessage("语言"),
    "light": MessageLookupByLibrary.simpleMessage("浅色"),
    "llmModelExample": MessageLookupByLibrary.simpleMessage(
      "比如 “gemini-3-flash-preview”",
    ),
    "loadingAfterSeparatedStatus": MessageLookupByLibrary.simpleMessage(
      "生成成功！正在加载",
    ),
    "localStorageDir": MessageLookupByLibrary.simpleMessage("本地存储目录"),
    "lyricFile": MessageLookupByLibrary.simpleMessage("歌词文件"),
    "mixTable": MessageLookupByLibrary.simpleMessage("调音台"),
    "modelName": MessageLookupByLibrary.simpleMessage("模型名称"),
    "myLibrary": MessageLookupByLibrary.simpleMessage("我的曲库"),
    "network": MessageLookupByLibrary.simpleMessage("网络"),
    "networkProxy": MessageLookupByLibrary.simpleMessage("网络代理"),
    "noProject": MessageLookupByLibrary.simpleMessage("暂无项目"),
    "openLocal": MessageLookupByLibrary.simpleMessage("打开本地"),
    "optionalServiceUrl": MessageLookupByLibrary.simpleMessage("服务 URL（可选）"),
    "pause": MessageLookupByLibrary.simpleMessage("暂停"),
    "phaseFailedStatus": m1,
    "pitch": MessageLookupByLibrary.simpleMessage("音调"),
    "play": MessageLookupByLibrary.simpleMessage("播放"),
    "playFromStartPoint": MessageLookupByLibrary.simpleMessage("从起点播放"),
    "playbackRate": MessageLookupByLibrary.simpleMessage("速度"),
    "processing": MessageLookupByLibrary.simpleMessage("处理中"),
    "projectDeletedHint": m2,
    "queueStatus": m3,
    "readAloudCurrentLyric": MessageLookupByLibrary.simpleMessage("朗读当前歌词"),
    "readAloudLyric": MessageLookupByLibrary.simpleMessage("朗读歌词"),
    "regenerateExplanation": MessageLookupByLibrary.simpleMessage("重新解释"),
    "regenerateSubtitle": MessageLookupByLibrary.simpleMessage("重新生成副标题"),
    "searchOnline": MessageLookupByLibrary.simpleMessage("在线搜索"),
    "selectAudioFile": MessageLookupByLibrary.simpleMessage("选择音频文件"),
    "selectService": MessageLookupByLibrary.simpleMessage("选择服务"),
    "separatingStatus": MessageLookupByLibrary.simpleMessage("正在分离人声和伴奏"),
    "settings": MessageLookupByLibrary.simpleMessage("设置"),
    "startingProgress": MessageLookupByLibrary.simpleMessage("正在执行"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "successOfTest": MessageLookupByLibrary.simpleMessage("成功"),
    "supportAudioInputsHint": MessageLookupByLibrary.simpleMessage(
      "支持 Youtube 链接或本地文件",
    ),
    "targetLanguage": MessageLookupByLibrary.simpleMessage("目标语言"),
    "test": MessageLookupByLibrary.simpleMessage("测试"),
    "testing": MessageLookupByLibrary.simpleMessage("正在测试"),
    "textProcessing": MessageLookupByLibrary.simpleMessage("文字处理"),
    "textProcessingTest": MessageLookupByLibrary.simpleMessage("文字处理测试"),
    "theme": MessageLookupByLibrary.simpleMessage("主题"),
    "translate": MessageLookupByLibrary.simpleMessage("翻译"),
    "translateLyric": MessageLookupByLibrary.simpleMessage("翻译歌词"),
    "translateTo": MessageLookupByLibrary.simpleMessage("翻译成："),
    "ttsModelExample": MessageLookupByLibrary.simpleMessage(
      "比如 “gemini-2.5-flash-preview-tts”",
    ),
    "undo": MessageLookupByLibrary.simpleMessage("撤销"),
    "uploading": MessageLookupByLibrary.simpleMessage("正在上传"),
    "version": MessageLookupByLibrary.simpleMessage("版本"),
    "vocalIsolation": MessageLookupByLibrary.simpleMessage("人声分离"),
    "voiceGeneration": MessageLookupByLibrary.simpleMessage("语音生成"),
    "voiceTest": MessageLookupByLibrary.simpleMessage("语音测试"),
    "volume": MessageLookupByLibrary.simpleMessage("音量"),
    "wholeLyricCopyed": MessageLookupByLibrary.simpleMessage("已复制全部歌词"),
    "wordByWordExplanation": MessageLookupByLibrary.simpleMessage("逐词解释"),
  };
}
