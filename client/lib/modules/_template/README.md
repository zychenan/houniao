# 模块模板

复制 `template_module.dart` 和 `template_view.dart`，替换以下占位符：

1. `TemplateModule` → 你的模块名
2. `your_module_type` → 唯一标识符（小写英文，如 `tasks`）
3. 选择 `mergeStrategy` 和 `reliability`
4. 在 `app.dart` 中注册模块并添加 Tab

## 5 分钟示例

```dart
// 1. 创建 todo_module.dart
class TodoModule {
  static const moduleType = 'todos';
  TodoModule(SyncCore core) { ... }
}

// 2. 在 app.dart 中注册
final todos = TodoModule(_core);

// 3. 添加 Tab
Tab(text: '待办', ...)
```
