import 'package:photofilters/filters/filters.dart';
import 'package:photofilters/filters/image_filters.dart';
import 'package:photofilters/filters/subfilters.dart';
import 'package:photofilters/utils/convolution_kernels.dart';

class IdentityFilter extends ImageFilter {
  IdentityFilter() : super(name: "Identity") {
    subFilters.add(ConvolutionSubFilter.fromKernel(identityKernel));
  }
}

class EmbossFilter extends ImageFilter {
  EmbossFilter() : super(name: "Emboss") {
    subFilters.add(ConvolutionSubFilter.fromKernel(embossKernel));
  }
}

class SharpenFilter extends ImageFilter {
  SharpenFilter() : super(name: "Sharpen") {
    subFilters.add(ConvolutionSubFilter.fromKernel(sharpenKernel));
  }
}

class ColoredEdgeFilter extends ImageFilter {
  ColoredEdgeFilter() : super(name: "Colored Edge") {
    subFilters.add(ConvolutionSubFilter.fromKernel(coloredEdgeDetectionKernel));
  }
}

class BlurFilter extends ImageFilter {
  BlurFilter() : super(name: "Blur") {
    subFilters.add(ConvolutionSubFilter.fromKernel(blurKernel));
  }
}

class EdgeDetectionMediumFilter extends ImageFilter {
  EdgeDetectionMediumFilter() : super(name: "Edge Detection Medium") {
    subFilters.add(ConvolutionSubFilter.fromKernel(edgeDetectionMediumKernel));
  }
}

class EdgeDetectionHardFilter extends ImageFilter {
  EdgeDetectionHardFilter() : super(name: "Edge Detection Hard") {
    subFilters.add(ConvolutionSubFilter.fromKernel(edgeDetectionHardKernel));
  }
}

class Gaussian3x3Filter extends ImageFilter {
  Gaussian3x3Filter() : super(name: "Gaussian3x3") {
    subFilters.add(ConvolutionSubFilter.fromKernel(gaussian3x3Kernel));
  }
}

class Gaussian5x5Filter extends ImageFilter {
  Gaussian5x5Filter() : super(name: "Gaussian5x5") {
    subFilters.add(ConvolutionSubFilter.fromKernel(gaussian5x5Kernel));
  }
}

class Gaussian7x7Filter extends ImageFilter {
  Gaussian7x7Filter() : super(name: "Gaussian7x7") {
    subFilters.add(ConvolutionSubFilter.fromKernel(gaussian7x7Kernel));
  }
}

class LowPass3x3Filter extends ImageFilter {
  LowPass3x3Filter() : super(name: "LowPass3x3") {
    subFilters.add(ConvolutionSubFilter.fromKernel(lowPass3x3Kernel));
  }
}

class LowPass5x5Filter extends ImageFilter {
  LowPass5x5Filter() : super(name: "LowPass5x5") {
    subFilters.add(ConvolutionSubFilter.fromKernel(lowPass5x5Kernel));
  }
}

class Mean3x3Filter extends ImageFilter {
  Mean3x3Filter() : super(name: "Mean3x3") {
    subFilters.add(ConvolutionSubFilter.fromKernel(mean3x3Kernel));
  }
}

class Mean5x5Filter extends ImageFilter {
  Mean5x5Filter() : super(name: "Mean5x5") {
    subFilters.add(ConvolutionSubFilter.fromKernel(mean5x5Kernel));
  }
}

List<Filter> convolutionFilters = [
  IdentityFilter(),
  EmbossFilter(),
  SharpenFilter(),
  ColoredEdgeFilter(),
  BlurFilter(),
  EdgeDetectionMediumFilter(),
  EdgeDetectionHardFilter(),
  Gaussian3x3Filter(),
  Gaussian5x5Filter(),
  Gaussian7x7Filter(),
  LowPass3x3Filter(),
  LowPass5x5Filter(),
  Mean3x3Filter(),
  Mean5x5Filter(),
];
