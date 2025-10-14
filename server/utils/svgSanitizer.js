const allowedTags = new Set([
  'path',
  'circle',
  'rect',
  'line',
  'polyline',
  'polygon',
  'ellipse',
  'g',
]);

const allowedAttributes = new Set([
  'd',
  'points',
  'fill',
  'stroke',
  'stroke-width',
  'stroke-linecap',
  'stroke-linejoin',
  'stroke-dasharray',
  'stroke-dashoffset',
  'strokeLinecap'.toLowerCase(),
  'strokeLinejoin'.toLowerCase(),
  'strokeWidth'.toLowerCase(),
  'strokeDasharray'.toLowerCase(),
  'strokeDashoffset'.toLowerCase(),
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
]);

const sanitizeSvgFragment = svgContent => {
  if (!svgContent || typeof svgContent !== 'string') {
    return '';
  }

  const fragment = svgContent.trim();

  if (!fragment) {
    return '';
  }

  const forbiddenPatterns = [
    /<\s*script/i,
    /on[a-z]+\s*=/i,
    /javascript:/i,
    /<\s*foreignobject/i,
    /<\s*iframe/i,
    /<\s*style/i,
  ];

  if (forbiddenPatterns.some(pattern => pattern.test(fragment))) {
    throw new Error('Ícone contém elementos perigosos');
  }

  const tagRegex = /<\s*\/?\s*([a-zA-Z0-9:_-]+)([^>]*)>/g;
  const attributeRegex = /([a-zA-Z_:][\w:.-]*)\s*=\s*"[^"]*"/g;
  const stack = [];

  let match;
  let lastIndex = 0;

  while ((match = tagRegex.exec(fragment)) !== null) {
    const textBetween = fragment.slice(lastIndex, match.index);

    if (textBetween.trim()) {
      throw new Error('Texto não permitido dentro do fragmento SVG');
    }

    lastIndex = tagRegex.lastIndex;

    const rawTagName = match[1];
    const tagName = rawTagName.toLowerCase();

    if (!allowedTags.has(tagName)) {
      throw new Error(`Tag SVG não permitida: <${rawTagName}>`);
    }

    const isClosingTag = match[0].startsWith('</');
    const attributesPart = match[2] || '';
    const isSelfClosing =
      /\/\s*>$/.test(match[0]) || attributesPart.trim().endsWith('/');

    if (!isClosingTag) {
      if (
        /style\s*=|href\s*=|xlink:href\s*=|formaction\s*=/i.test(attributesPart)
      ) {
        throw new Error('Atributo SVG não permitido');
      }

      let attributeMatch;
      while ((attributeMatch = attributeRegex.exec(attributesPart)) !== null) {
        const attrNameOriginal = attributeMatch[1];
        const attrName = attrNameOriginal.toLowerCase();

        if (!allowedAttributes.has(attrName)) {
          throw new Error(`Atributo SVG não permitido: ${attrNameOriginal}`);
        }
      }

      const leftover = attributesPart
        .replace(attributeRegex, '')
        .replace('/', '')
        .trim();

      if (leftover) {
        throw new Error(`Formato de atributo inválido em <${rawTagName}>`);
      }

      if (!isSelfClosing) {
        stack.push(tagName);
      }
    } else {
      if (!stack.length || stack.pop() !== tagName) {
        throw new Error('Tags SVG não estão balanceadas');
      }
    }
  }

  if (lastIndex < fragment.length && fragment.slice(lastIndex).trim()) {
    throw new Error('Texto não permitido após o último elemento SVG');
  }

  if (stack.length) {
    throw new Error('Tags SVG não estão corretamente fechadas');
  }

  return fragment;
};

module.exports = sanitizeSvgFragment;
