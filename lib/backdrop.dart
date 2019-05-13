import 'package:flutter/material.dart';

const double _kFlingVelocity = 2.0;

class Backdrop extends StatefulWidget {
  final Widget frontLayer;
  final Widget backLayer;
  final Widget frontTitle;
  final Widget backTitle;

  const Backdrop({
    Key key,
    this.frontLayer,
    this.backLayer,
    this.frontTitle,
    this.backTitle,
  })  : assert(frontLayer != null),
        assert(backLayer != null),
        assert(frontTitle != null),
        assert(backTitle != null),
        super(key: key);

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with SingleTickerProviderStateMixin {
  final GlobalKey _backdropKey = GlobalKey(debugLabel: 'Backdrop');

  AnimationController _controller;

  bool get _frontLayerVisible {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed || status == AnimationStatus.forward;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    if (_controller != null) _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Backdrop oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_frontLayerVisible) _controller.fling(velocity: _kFlingVelocity);
  }

  void _toggleBackdropLayerVisibility() {
    _controller.fling(velocity: _frontLayerVisible ? -_kFlingVelocity : _kFlingVelocity);
  }

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    // AppBarの高さ
    const double layerTitleHeight = 48.0;
    // 全体のサイズ
    final Size layerSize = constraints.biggest;
    // AppBarを引いたTopの位置
    final double layerTop = layerSize.height - layerTitleHeight;

    Animation<RelativeRect> layerAnimation = RelativeRectTween(
      begin: RelativeRect.fromLTRB(0.0, layerTop, 0.0, layerTop - layerSize.height),
      end: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
    ).animate(_controller.view);

    return Stack(
      key: _backdropKey,
      children: <Widget>[
        ExcludeSemantics(
          child: widget.backLayer,
          excluding: _frontLayerVisible,
        ),
        PositionedTransition(
          rect: layerAnimation,
          child: _FrontLayer(
            child: widget.frontLayer,
            onTap: _toggleBackdropLayerVisibility,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _BackdropTitle(
          frontTitle: widget.frontTitle,
          backTitle: widget.backTitle,
          listenable: _controller.view,
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _toggleBackdropLayerVisibility,
            icon: Icon(Icons.tune),
          ),
        ],
      ),
      body: LayoutBuilder(builder: _buildStack),
    );
  }
}

class _BackdropTitle extends AnimatedWidget {
  final Widget frontTitle;
  final Widget backTitle;

  const _BackdropTitle({
    Key key,
    Listenable listenable,
    @required this.frontTitle,
    @required this.backTitle,
  })  : assert(frontTitle != null),
        assert(backTitle != null),
        super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = this.listenable;

    return DefaultTextStyle(
      style: Theme.of(context).primaryTextTheme.title,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: Stack(
        children: <Widget>[
          Opacity(
            opacity: CurvedAnimation(
              parent: ReverseAnimation(animation),
              curve: Interval(0.5, 1.0),
            ).value,
            child: FractionalTranslation(
              translation: Tween<Offset>(
                begin: Offset.zero,
                end: Offset(0.5, 0.0),
              ).evaluate(animation),
              child: backTitle,
            ),
          ),
          Opacity(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Interval(0.5, 1.0),
            ).value,
            child: FractionalTranslation(
              translation: Tween<Offset>(
                begin: Offset(-0.25, 0.0),
                end: Offset.zero,
              ).evaluate(animation),
              child: frontTitle,
            ),
          ),
        ],
      ),
    );
  }
}

const double _kDefaultElevation = 16.0;
const double _kDefaultRadius = 46.0;
const double _kDefaultTapAreaHeight = 40.0;

class _FrontLayer extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double elevation;
  final double radius;
  final double tapAreaHeight;

  const _FrontLayer({
    Key key,
    this.onTap,
    this.child,
    this.elevation,
    this.radius,
    this.tapAreaHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation ?? _kDefaultElevation,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius ?? _kDefaultRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            // 空白部分をタップに含める
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              height: tapAreaHeight ?? _kDefaultTapAreaHeight,
              alignment: AlignmentDirectional.centerStart,
            ),
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
