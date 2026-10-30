import 'package:flutter/material.dart';
import '../../models/resource_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';

class ManageResources extends StatefulWidget {
  const ManageResources({super.key});

  @override
  State<ManageResources> createState() => _ManageResourcesState();
}

class _ManageResourcesState extends State<ManageResources> {
  List<Resource> _myResources = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedCategory = 'Guide';

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      final user = await Services.auth.getCurrentUser();
      if (user != null) {
        final all = await Services.db.getResources();
        // Filter resources uploaded by this specific counsellor (or display all but let them edit/delete their own)
        setState(() {
          _myResources = all.where((r) => r.uploadedBy == user.uid).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveResource({Resource? existingResource}) async {
    if (!_formKey.currentState!.validate()) return;

    final title = Validators.sanitizeText(_titleController.text);
    final desc = Validators.sanitizeText(_descController.text);
    final url = _urlController.text.trim();

    try {
      final user = await Services.auth.getCurrentUser();
      if (user == null) throw Exception('User session invalid');

      if (existingResource != null) {
        // Edit existing resource
        final updated = Resource(
          id: existingResource.id,
          title: title,
          description: desc,
          category: _selectedCategory,
          url: url,
          uploadedBy: existingResource.uploadedBy,
          uploadedByName: existingResource.uploadedByName,
          createdAt: existingResource.createdAt,
        );
        await Services.db.updateResource(updated);
      } else {
        // Add new resource
        final newRes = Resource(
          id: 'res-${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: desc,
          category: _selectedCategory,
          url: url,
          uploadedBy: user.uid,
          uploadedByName: user.name,
          createdAt: DateTime.now(),
        );
        await Services.db.createResource(newRes);
      }

      if (!mounted) return;
      Navigator.pop(context);
      _loadResources();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource published successfully!'), backgroundColor: AppTheme.alertSuccess),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}'), backgroundColor: AppTheme.alertSevere),
      );
    }
  }

  Future<void> _deleteResource(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.slateDark,
        title: const Text('Delete Resource'),
        content: const Text('Are you sure you want to permanently delete this resource?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertSevere, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Services.db.deleteResource(id);
      _loadResources();
    }
  }

  void _openResourceDialog({Resource? resource}) {
    if (resource != null) {
      _titleController.text = resource.title;
      _descController.text = resource.description;
      _urlController.text = resource.url;
      _selectedCategory = resource.category;
    } else {
      _titleController.clear();
      _descController.clear();
      _urlController.clear();
      _selectedCategory = 'Guide';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.slateDark,
              title: Text(resource != null ? 'Edit Resource' : 'Publish Wellness Resource'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category selection
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        dropdownColor: AppTheme.slateCard,
                        decoration: const InputDecoration(labelText: 'Resource Category'),
                        items: ['Guide', 'Video', 'Audio', 'PDF'].map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              _selectedCategory = v;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (v) => Validators.validateRequired(v, 'Title', maxLen: 80),
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Description'),
                        validator: (v) => Validators.validateRequired(v, 'Description', maxLen: 300),
                      ),
                      const SizedBox(height: 16),
                      // URL
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(labelText: 'URL Link (e.g. YouTube/PDF Link)'),
                        validator: Validators.validateUrl,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _saveResource(existingResource: resource),
                  child: const Text('Publish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Management'),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
            : _myResources.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_add_rounded, size: 64, color: AppTheme.textLow.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'You have not uploaded any wellness resources yet.',
                          style: TextStyle(color: AppTheme.textLow),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _myResources.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final res = _myResources[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.tealPrimary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      res.category.toUpperCase(),
                                      style: const TextStyle(color: AppTheme.tealPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: AppTheme.mintAccent, size: 20),
                                      onPressed: () => _openResourceDialog(resource: res),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.alertSevere, size: 20),
                                      onPressed: () => _deleteResource(res.id),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              res.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              res.description,
                              style: const TextStyle(color: AppTheme.textMedium),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'URL: ${res.url}',
                              style: const TextStyle(color: AppTheme.textLow, fontSize: 11, fontStyle: FontStyle.italic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.lilacAccent,
        foregroundColor: AppTheme.spaceDark,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Resource'),
        onPressed: () => _openResourceDialog(),
      ),
    );
  }
}
