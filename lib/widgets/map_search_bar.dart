import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mapa_ule/models/destination.dart';

class MapSearchBar extends StatefulWidget {
  final List<Destination> destinations;
  final Function(Destination) onSearch;

  const MapSearchBar({
    super.key,
    required this.destinations,
    required this.onSearch,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  @override
  Widget build(BuildContext context) {
    return searchBar();
  }

  Container searchBar() {
    return Container(
      padding: EdgeInsets.all(10.0),
      width: double.infinity,
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Autocomplete(
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Buscar destino',
                  prefixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      if (textEditingController.text.isNotEmpty) {
                        var match = widget.destinations.firstWhereOrNull(
                          (d) => d.name.toLowerCase().contains(
                            textEditingController.text.toLowerCase(),
                          ),
                        );
                        if (match != null) {
                          widget.onSearch(match);
                          FocusScope.of(context).unfocus();
                        }
                      }
                    },
                  ),
                ),
                onFieldSubmitted: (value) {
                  if (value.isNotEmpty) {
                    var match = widget.destinations.firstWhereOrNull(
                      (d) => d.name.toLowerCase().contains(
                        textEditingController.text.toLowerCase(),
                      ),
                    );
                    if (match != null) {
                      widget.onSearch(match);
                    }
                  }
                },
              );
            },
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<Destination>.empty();
          } else {
            return widget.destinations.where((destination) {
              return destination.name.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          }
        },
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: MediaQuery.of(context).size.width,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final Destination option = options.elementAt(index);
                  return ListTile(
                    title: Text(option.name),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        ),
        displayStringForOption: (Destination option) => option.name,
        onSelected: (option) => {widget.onSearch(option)},
      ),
    );
  }
}
