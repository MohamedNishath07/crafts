if (newInteraction != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery action logged successfully')),
      );
      ref.read(interactionControllerProvider.notifier).refresh();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log recovery action')),
      );
    }