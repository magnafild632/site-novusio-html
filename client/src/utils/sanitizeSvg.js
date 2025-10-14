import DOMPurify from 'dompurify';

const ALLOWED_TAGS = [
  'path',
  'circle',
  'rect',
  'line',
  'polyline',
  'polygon',
  'ellipse',
  'g',
];

const ALLOWED_ATTRIBUTES = [
  'd',
  'points',
  'fill',
  'stroke',
  'stroke-width',
  'stroke-linecap',
  'stroke-linejoin',
  'stroke-dasharray',
  'stroke-dashoffset',
  'strokeLinecap',
  'strokeLinejoin',
  'strokeWidth',
  'strokeDasharray',
  'strokeDashoffset',
  'cx',
  'cy',
  'r',
  'rx',
  'ry',
  'x',
  'y',
  'x1',
  'y1',
  'x2',
  'y2',
  'width',
  'height',
  'transform',
  'opacity',
  'data-name',
];

const sanitizeSvgFragment = svgContent => {
  if (!svgContent || typeof svgContent !== 'string') {
    return '';
  }

  return DOMPurify.sanitize(svgContent, {
    ALLOWED_TAGS,
    ALLOWED_ATTR: ALLOWED_ATTRIBUTES,
    USE_PROFILES: { svg: true },
  });
};

export default sanitizeSvgFragment;
