import 'package:flutter/material.dart';

enum ListItemType { leading, title, subtitle, trailing }

class CustomListWidget<T> extends StatefulWidget {
  final List<T> items;
  final Function listItemBuilder;
  final bool? checkable;
  final bool? multiSelection;
  final Set<T>? selectedItems;
  final Widget? trailing;
  final ValueChanged<Set<T>>? onTap;
  final ScrollPhysics? physics;

  const CustomListWidget({
    Key? key,
    required this.items,
    required this.listItemBuilder,
    this.checkable,
    this.multiSelection,
    this.selectedItems,
    this.onTap,
    this.trailing,
    this.physics = const NeverScrollableScrollPhysics(),
  }) : super(key: key);

  @override
  CustomListWidgetState<T> createState() => CustomListWidgetState<T>();
}

class CustomListWidgetState<T> extends State<CustomListWidget<T>> {
  late Set<T> _selectedItems;

  @override
  void initState() {
    _selectedItems = (widget.selectedItems ?? {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: widget.physics,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: widget.items.length,
      itemBuilder: (context, index) => Card(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 1),
        child: ListTile(
          textColor: Colors.grey[800] as Color,
          onTap: () {
            setState(() {
              var currentItem = widget.items[index];

              if (widget.multiSelection == false) {
                if (!_selectedItems.contains(currentItem)) {
                  _selectedItems.clear();
                  _selectedItems.add(currentItem);
                }
              } else {
                if (_selectedItems.contains(currentItem)) {
                  _selectedItems.remove(currentItem);
                } else {
                  _selectedItems.add(currentItem);
                }
              }
              widget.onTap!(_selectedItems);
            });
          },
          enabled: true,
          leading:
              widget.listItemBuilder(ListItemType.leading, widget.items[index]),
          title:
              widget.listItemBuilder(ListItemType.title, widget.items[index]),
          subtitle: widget.listItemBuilder(
              ListItemType.subtitle, widget.items[index]),
          trailing: widget.checkable == true
              ? _checkableTrailing(index)
              : widget.listItemBuilder(
                  ListItemType.trailing, widget.items[index]),
        ),
      ),
    );
  }

  Widget? _checkableTrailing(int index) {
    if (_selectedItems.contains(widget.items.elementAt(index))) {
      return const Icon(
        Icons.check_sharp,
        color: Colors.blueAccent,
        size: 30,
      );
    }
    return null;
  }
}
