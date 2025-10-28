export class ImageFilters {
  static filters = {
    normal: { name: 'Normal', css: '' },
    clarendon: { name: 'Clarendon', css: 'contrast(1.2) saturate(1.35)' },
    gingham: { name: 'Gingham', css: 'brightness(1.05) hue-rotate(-10deg)' },
    moon: { name: 'Moon', css: 'grayscale(1) contrast(1.1) brightness(1.1)' },
    lark: { name: 'Lark', css: 'contrast(0.9) brightness(1.1) saturate(1.2)' },
    reyes: { name: 'Reyes', css: 'sepia(0.22) brightness(1.1) contrast(0.85) saturate(0.75)' },
    juno: { name: 'Juno', css: 'sepia(0.35) contrast(1.15) brightness(1.15) saturate(1.8)' },
    slumber: { name: 'Slumber', css: 'saturate(0.66) brightness(1.05)' },
    crema: { name: 'Crema', css: 'sepia(0.5) contrast(1.25) brightness(1.15) saturate(0.9) hue-rotate(-2deg)' },
    ludwig: { name: 'Ludwig', css: 'contrast(1.15) brightness(1.05) saturate(1.3)' },
    aden: { name: 'Aden', css: 'hue-rotate(-20deg) contrast(0.9) saturate(0.85) brightness(1.2)' },
    perpetua: { name: 'Perpetua', css: 'contrast(1.1) saturate(1.1)' },
    amaro: { name: 'Amaro', css: 'hue-rotate(-10deg) contrast(0.9) brightness(1.1) saturate(1.5)' },
    mayfair: { name: 'Mayfair', css: 'contrast(1.1) saturate(1.1)' },
    rise: { name: 'Rise', css: 'brightness(1.05) sepia(0.2) contrast(0.9) saturate(0.9)' },
    hudson: { name: 'Hudson', css: 'brightness(1.2) contrast(0.9) saturate(1.1)' },
    valencia: { name: 'Valencia', css: 'sepia(0.08) contrast(1.08) brightness(1.08) saturate(1.3)' },
    xpro2: { name: 'X-Pro II', css: 'sepia(0.3) contrast(1.3) brightness(0.8) saturate(1.5)' },
    sierra: { name: 'Sierra', css: 'contrast(0.9) brightness(1.1) sepia(0.25) saturate(0.75)' },
    willow: { name: 'Willow', css: 'grayscale(0.5) contrast(0.95) brightness(0.9)' },
    lofi: { name: 'Lo-Fi', css: 'contrast(1.5) saturate(1.1)' },
    inkwell: { name: 'Inkwell', css: 'grayscale(1) contrast(1.1) brightness(1.1)' },
    nashville: { name: 'Nashville', css: 'sepia(0.25) contrast(1.2) brightness(1.05) saturate(1.2)' },
    jaipur: { name: 'Jaipur', css: 'brightness(1.1) contrast(0.9) saturate(1.15) hue-rotate(10deg)' },
    cairo: { name: 'Cairo', css: 'sepia(0.25) contrast(1.1) brightness(0.95) saturate(1.1)' },
    tokyo: { name: 'Tokyo', css: 'grayscale(1) contrast(1.3) brightness(1.05)' },
    rio: { name: 'Rio', css: 'brightness(1.1) contrast(1.05) saturate(1.3) hue-rotate(25deg)' },
    abuDhabi: { name: 'Abu Dhabi', css: 'contrast(1.05) brightness(1.2) saturate(0.9)' },
    lagos: { name: 'Lagos', css: 'sepia(0.2) contrast(1.15) brightness(1.05) saturate(1.1)' },
    bangkok: { name: 'Bangkok', css: 'contrast(1.1) brightness(1.05) hue-rotate(-15deg)' },
    losAngeles: { name: 'Los Angeles', css: 'contrast(1.05) brightness(1.1) saturate(1.1)' },
    oslo: { name: 'Oslo', css: 'contrast(0.9) brightness(1.15) saturate(0.8)' },
    jakarta: { name: 'Jakarta', css: 'contrast(1.05) brightness(1.1) saturate(1.15) hue-rotate(10deg)' },
    buenosAires: { name: 'Buenos Aires', css: 'contrast(1.15) brightness(0.95) saturate(0.9) hue-rotate(-10deg)' },
    newYork: { name: 'New York', css: 'contrast(1.1) brightness(0.9) saturate(0.85) grayscale(0.1)' },
    miami: { name: 'Miami', css: 'contrast(1.1) brightness(1.05) saturate(1.3) hue-rotate(8deg)' },
    kyoto: { name: 'Kyoto', css: 'sepia(0.15) brightness(1.2) contrast(0.9) saturate(1.05)' },
    berlin: { name: 'Berlin', css: 'grayscale(0.8) contrast(1.05) brightness(1.15)' },
  };

  static apply(canvas, filterName) {
    const filter = this.filters[filterName];
    if (!filter) return canvas;
    
    const ctx = canvas.getContext('2d');
    const tempCanvas = document.createElement('canvas');
    tempCanvas.width = canvas.width;
    tempCanvas.height = canvas.height;
    const tempCtx = tempCanvas.getContext('2d');
    
    // Apply CSS filter
    tempCtx.filter = filter.css;
    tempCtx.drawImage(canvas, 0, 0);
    
    return tempCanvas;
  }

  static getFilterNames() {
    return Object.keys(this.filters);
  }

  static getFilterData(name) {
    return this.filters[name];
  }
}

