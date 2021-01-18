part of flutter_parse_sdk_flutter;

class ParseLiveGridWidget<T extends sdk.ParseObject> extends StatefulWidget {
  const ParseLiveGridWidget({
    Key key,
    @required this.query,
    this.gridLoadingElement,
    this.queryEmptyElement,
    this.duration = const Duration(milliseconds: 300),
    this.scrollPhysics,
    this.scrollController,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.primary,
    this.reverse = false,
    this.childBuilder,
    this.shrinkWrap = false,
    this.removedItemBuilder,
    this.listenOnAllSubItems,
    this.listeningIncludes,
    this.lazyLoading = true,
    this.preloadedColumns,
    this.animationController,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 5.0,
    this.mainAxisSpacing = 5.0,
    this.childAspectRatio = 0.80,
  }) : super(key: key);

  final sdk.QueryBuilder<T> query;
  final Widget gridLoadingElement;
  final Widget queryEmptyElement;
  final Duration duration;
  final ScrollPhysics scrollPhysics;
  final ScrollController scrollController;

  final Axis scrollDirection;
  final EdgeInsetsGeometry padding;
  final bool primary;
  final bool reverse;
  final bool shrinkWrap;

  final ChildBuilder<T> childBuilder;
  final ChildBuilder<T> removedItemBuilder;

  final bool listenOnAllSubItems;
  final List<String> listeningIncludes;

  final bool lazyLoading;
  final List<String> preloadedColumns;

  final AnimationController animationController;

  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  @override
  _ParseLiveGridWidgetState<T> createState() => _ParseLiveGridWidgetState<T>(
        query: query,
        removedItemBuilder: removedItemBuilder,
        listenOnAllSubItems: listenOnAllSubItems,
        listeningIncludes: listeningIncludes,
        lazyLoading: lazyLoading,
        preloadedColumns: preloadedColumns,
      );

  static Widget defaultChildBuilder<T extends sdk.ParseObject>(
      BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot) {
    Widget child;
    if (snapshot.failed) {
      child = const Text('something went wrong!');
    } else if (snapshot.hasData) {
      child = ListTile(
        title: Text(
          snapshot.loadedData.get(sdk.keyVarObjectId),
        ),
      );
    } else {
      child = const ListTile(
        leading: CircularProgressIndicator(),
      );
    }
    return child;
  }
}

class _ParseLiveGridWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveGridWidget<T>> {
  _ParseLiveGridWidgetState(
      {@required this.query,
      @required this.removedItemBuilder,
      bool listenOnAllSubItems,
      List<String> listeningIncludes,
      bool lazyLoading = true,
      List<String> preloadedColumns}) {
    sdk.ParseLiveList.create(
      query,
      listenOnAllSubItems: listenOnAllSubItems,
      listeningIncludes: listeningIncludes,
      lazyLoading: lazyLoading,
      preloadedColumns: preloadedColumns,
    ).then((sdk.ParseLiveList<T> value) {
      query.count().then((value) {
        if (value.count > 0) {
          setState(() {
            noData = false;
          });
        } else {
          setState(() {
            noData = true;
          });
        }
      });
      setState(() {
        _liveGrid = value;
        _liveGrid.stream
            .listen((sdk.ParseLiveListEvent<sdk.ParseObject> event) {
          if (mounted) {
            setState(() {});
          }
        });
      });
    });
  }

  final sdk.QueryBuilder<T> query;
  sdk.ParseLiveList<T> _liveGrid;
  final GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  final ChildBuilder<T> removedItemBuilder;
  bool noData = false;

  @override
  Widget build(BuildContext context) {
    return _liveGrid == null
        ? widget.gridLoadingElement ?? Container()
        : noData
            ? widget.queryEmptyElement ?? Container()
            : buildAnimatedGrid();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Widget buildAnimatedGrid() {
    AnimationController controller;
    Animation<double> boxAnimation;
    boxAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(
          0,
          0.5,
          curve: Curves.decelerate,
        ),
      ),
    );
    return GridView.builder(
        itemCount: _liveGrid?.size,
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing,
            childAspectRatio: widget.childAspectRatio),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          return ParseLiveListElementWidget<T>(
            key: ValueKey<String>(
                _liveGrid?.getIdentifier(index) ?? '_NotFound'),
            stream: () => _liveGrid?.getAt(index),
            loadedData: () => _liveGrid?.getLoadedAt(index),
            preLoadedData: () => _liveGrid?.getPreLoadedAt(index),
            sizeFactor: boxAnimation,
            duration: widget.duration,
            childBuilder:
                widget.childBuilder ?? ParseLiveGridWidget.defaultChildBuilder,
          );
        });
  }

  @override
  void dispose() {
    _liveGrid?.dispose();
    _liveGrid = null;
    super.dispose();
  }
}
