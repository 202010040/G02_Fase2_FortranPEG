const nodes = {
    Producciones: ['id', 'expr', 'alias'],
    Opciones: ['exprs'],
    Union: ['exprs'],
    Expresion: ['expr', 'label', 'qty'],
    String: ['val', 'isCase'],
    Clase: ['chars', 'isCase'],
    Rango: ['rangoInicial', 'rangoFinal'],
    Identificador: ['id'],
    Punto: [],
    Fin: [],
    Gramatica: ['producciones'],
    Etiqueta: ['id', 'varios'],
    Varios: ['symbol'],
    Conteo: ['min', 'max', 'opciones'],
    ContenidoClase: ['rangoInicial', 'rangoFinal'],
    Literal: ['value'],
    Caracter: ['char']
};


export default nodes;