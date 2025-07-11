import 'package:flutter/material.dart';

class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final bool enableAlpha;
  final List<ColorLabelType> labelTypes;
  final double pickerAreaHeightPercent;

  const ColorPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
    this.enableAlpha = true,
    this.labelTypes = const [],
    this.pickerAreaHeightPercent = 0.8,
  }) : super(key: key);

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _currentColor;
  late HSVColor _currentHsvColor;
  
  // 预定义颜色列表
  final List<Color> _presetColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.pickerColor;
    _currentHsvColor = HSVColor.fromColor(_currentColor);
  }

  void _updateColor(Color color) {
    setState(() {
      _currentColor = color;
      _currentHsvColor = HSVColor.fromColor(_currentColor);
    });
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 色相滑块
        _buildHueSlider(),
        const SizedBox(height: 16),
        
        // 饱和度和亮度选择器
        _buildSaturationValueSelector(),
        const SizedBox(height: 16),
        
        // 透明度滑块
        if (widget.enableAlpha) _buildAlphaSlider(),
        if (widget.enableAlpha) const SizedBox(height: 16),
        
        // 预设颜色
        _buildPresetColors(),
        const SizedBox(height: 16),
        
        // 当前选择的颜色
        _buildCurrentColorIndicator(),
      ],
    );
  }

  Widget _buildHueSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('色相'),
        const SizedBox(height: 8),
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                HSVColor.fromAHSV(1.0, 0, 1.0, 1.0).toColor(),
                HSVColor.fromAHSV(1.0, 60, 1.0, 1.0).toColor(),
                HSVColor.fromAHSV(1.0, 120, 1.0, 1.0).toColor(),
                HSVColor.fromAHSV(1.0, 180, 1.0, 1.0).toColor(),
                HSVColor.fromAHSV(1.0, 240, 1.0, 1.0).toColor(),
                HSVColor.fromAHSV(1.0, 300, 1.0, 1.0).toColor(),
                HSVColor.fromAHSV(1.0, 360, 1.0, 1.0).toColor(),
              ],
            ),
          ),
        ),
        Slider(
          value: _currentHsvColor.hue,
          min: 0,
          max: 360,
          onChanged: (value) {
            setState(() {
              _currentHsvColor = _currentHsvColor.withHue(value);
              _currentColor = _currentHsvColor.toColor();
            });
            widget.onColorChanged(_currentColor);
          },
        ),
      ],
    );
  }

  Widget _buildSaturationValueSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('饱和度 & 亮度'),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                HSVColor.fromAHSV(1.0, _currentHsvColor.hue, 1.0, 1.0).toColor(),
              ],
            ),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final width = box.size.width;
              final height = 200;
              
              final saturation = (localPosition.dx.clamp(0, width) / width).clamp(0.0, 1.0);
              final value = 1.0 - (localPosition.dy.clamp(0, height) / height).clamp(0.0, 1.0);
              
              setState(() {
                _currentHsvColor = _currentHsvColor.withSaturation(saturation).withValue(value);
                _currentColor = _currentHsvColor.toColor();
              });
              widget.onColorChanged(_currentColor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlphaSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('透明度'),
        const SizedBox(height: 8),
        Slider(
          value: _currentHsvColor.alpha,
          min: 0,
          max: 1,
          onChanged: (value) {
            setState(() {
              _currentHsvColor = _currentHsvColor.withAlpha(value);
              _currentColor = _currentHsvColor.toColor();
            });
            widget.onColorChanged(_currentColor);
          },
        ),
      ],
    );
  }

  Widget _buildPresetColors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('预设颜色'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((color) {
            return GestureDetector(
              onTap: () => _updateColor(color),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCurrentColorIndicator() {
    return Row(
      children: [
        const Text('当前颜色: '),
        const SizedBox(width: 8),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _currentColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Text('HEX: #${_currentColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}'),
      ],
    );
  }
}

enum ColorLabelType {
  hex,
  rgb,
  hsv,
} 