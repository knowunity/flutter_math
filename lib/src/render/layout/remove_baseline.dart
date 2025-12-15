import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RemoveBaseline extends SingleChildRenderObjectWidget {
  const RemoveBaseline({super.key, required Widget super.child});

  @override
  RenderRemoveBaseline createRenderObject(BuildContext context) =>
      RenderRemoveBaseline();
}

class RenderRemoveBaseline extends RenderProxyBox {
  RenderRemoveBaseline({RenderBox? child}) : super(child);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => null;
}
