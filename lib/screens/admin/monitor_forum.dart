import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';

class MonitorForum extends StatefulWidget {
  const MonitorForum({super.key});

  @override
  State<MonitorForum> createState() => _MonitorForumState();
}

class _MonitorForumState extends State<MonitorForum> {
  List<ForumPost> _allPosts = [];
  bool _isLoading = true;

  final _warningController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadAllPosts();
  }

  Future<void> _loadAllPosts() async {
    try {
      final list = await Services.db.getAllForumPosts();
      setState(() {
        _allPosts = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.slateDark,
        title: const Text('Remove Post'),
        content: const Text(
          'Are you sure you want to permanently remove this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertSevere,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Services.db.removeForumPost(id);
      _loadAllPosts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post removed successfully.'),
          backgroundColor: AppTheme.alertSevere,
        ),
      );
    }
  }

  Future<void> _warnStudent(String studentId, String pseudonym) async {
    _warningController.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.slateDark,
          title: Text('Issue Warning to student ($pseudonym)'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _warningController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Warning Message',
                hintText: 'Enter reason for warning (e.g. inappropriate language)...',
              ),
              validator: (v) => Validators.validateRequired(v, 'Warning details', maxLen: 300),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.alertSevere,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Send Alert Warning'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final warningMsg = Validators.sanitizeText(_warningController.text);
      await Services.db.warnUser(studentId, warningMsg);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Administrative warning issued to student ($pseudonym).'),
          backgroundColor: AppTheme.alertWarning,
        ),
      );
    }
  }

  @override
  void dispose() {
    _warningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Moderation'),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
            : _allPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 64,
                          color: AppTheme.textLow.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No posts in the forum yet.',
                          style: TextStyle(color: AppTheme.textLow),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allPosts.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final post = _allPosts[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.studentPseudonym,
                                        style: const TextStyle(
                                          color: AppTheme.lilacAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                                        style: const TextStyle(
                                          color: AppTheme.textLow,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.alertSuccess.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.alertSuccess.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: AppTheme.alertSuccess,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16, color: Colors.white10),
                            Text(
                              post.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.content,
                              style: const TextStyle(
                                color: AppTheme.textMedium,
                                height: 1.4,
                                fontSize: 13,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            // Action buttons — wrap on small screens
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.alertWarning,
                                    side: BorderSide(
                                      color: AppTheme.alertWarning.withValues(alpha: 0.3),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.warning_amber_rounded, size: 15),
                                  label: const Text('Warn User', style: TextStyle(fontSize: 12)),
                                  onPressed: () =>
                                      _warnStudent(post.studentId, post.studentPseudonym),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.alertSevere,
                                    side: BorderSide(
                                      color: AppTheme.alertSevere.withValues(alpha: 0.3),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.delete_forever_rounded, size: 15),
                                  label: const Text('Remove Post', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _deletePost(post.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
