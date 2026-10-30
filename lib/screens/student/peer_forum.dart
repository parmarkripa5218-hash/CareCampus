import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../utils/security.dart';
import '../../utils/validators.dart';

class PeerForum extends StatefulWidget {
  const PeerForum({super.key});

  @override
  State<PeerForum> createState() => _PeerForumState();
}

class _PeerForumState extends State<PeerForum> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  List<ForumPost> _approvedPosts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadForumPosts();
  }

  Future<void> _loadForumPosts() async {
    try {
      final list = await Services.db.getApprovedForumPosts();
      setState(() {
        _approvedPosts = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final title = Validators.sanitizeText(_titleController.text);
    final content = Validators.sanitizeText(_contentController.text);

    try {
      final student = await Services.auth.getCurrentUser();
      if (student == null) throw Exception('User not logged in');

      // Generate secure pseudonym
      final pseudonym = SecurityUtils.generatePseudonym(student.uid);

      final newPost = ForumPost(
        id: 'post-${DateTime.now().millisecondsSinceEpoch}',
        studentId: student.uid,
        studentPseudonym: pseudonym,
        title: title,
        content: content,
        status: 'approved',
        createdAt: DateTime.now(),
      );

      await Services.db.createForumPost(newPost);
      
      if (!mounted) return;
      _titleController.clear();
      _contentController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post published successfully! It is now visible to the community.'),
          backgroundColor: AppTheme.alertSuccess,
        ),
      );
      Navigator.of(context).pop();
      _loadForumPosts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit post: ${e.toString()}'),
          backgroundColor: AppTheme.alertSevere,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _openCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.slateDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Anonymous Post',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share your thoughts, feelings, or questions. Your post is completely anonymous and will appear immediately.',
                    style: TextStyle(color: AppTheme.textLow, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Title Input
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Topic Title',
                      hintText: 'e.g., Struggling with midterms',
                    ),
                    validator: (v) => Validators.validateRequired(v, 'Title', maxLen: 80),
                  ),
                  const SizedBox(height: 16),

                  // Content Input
                  TextFormField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Post Body',
                      hintText: 'Describe how you feel or what support you need...',
                    ),
                    validator: (v) => Validators.validateRequired(v, 'Post body', maxLen: 1000),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPost,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppTheme.spaceDark),
                            ),
                          )
                        : const Text('Publish Post'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Peer Forum'),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
            : Column(
                children: [
                  // Info header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: AppTheme.slateCard.withValues(alpha: 0.2),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: AppTheme.mintAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your privacy matters: Student identities are replaced with pseudonyms. Posts publish immediately. Admins can remove inappropriate content.',
                            style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  // Posts List
                  Expanded(
                    child: _approvedPosts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.forum_outlined, size: 64, color: AppTheme.textLow.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No posts have been published yet.',
                                    style: TextStyle(color: AppTheme.textLow),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Be the first to share your thoughts by tapping the button below!',
                                    style: TextStyle(color: AppTheme.textLow, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: _approvedPosts.length,
                            separatorBuilder: (_, i) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final post = _approvedPosts[index];
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: AppTheme.glassCardDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: AppTheme.lilacAccent.withValues(alpha: 0.15),
                                                child: const Icon(Icons.person_rounded, size: 12, color: AppTheme.lilacAccent),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  post.studentPseudonym,
                                                  style: const TextStyle(
                                                    color: AppTheme.lilacAccent,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                                          style: const TextStyle(color: AppTheme.textLow, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      post.title,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      post.content,
                                      style: const TextStyle(color: AppTheme.textMedium, height: 1.4),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.tealPrimary,
        foregroundColor: AppTheme.spaceDark,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('New Post'),
        onPressed: _openCreatePostDialog,
      ),
    );
  }
}
