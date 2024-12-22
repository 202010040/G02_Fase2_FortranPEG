const nodes = {
    Producciones: ['id', 'expr', 'alias'],
    Opciones: ['exprs'],
    Union: ['exprs'],
    Expresion: ['expr', 'label', 'qty'],
    String: ['val', 'isCase'],
    Clase: ['chars', 'isCase'],
    Rango: ['rangoInicial', 'rangoFinal']
};

export default nodes;