{{
    import { ids, usos } from '../index.js'
    import { ErrorReglas } from './error.js';
    import { errores } from '../index.js';
    import * as n from '../visitor/CST.js';
}} 

gramatica = _ prods:producciones+ _ {

    let duplicados = ids.filter((item, index) => ids.indexOf(item) !== index);
    if (duplicados.length > 0) {
        errores.push(new ErrorReglas("Regla duplicada: " + duplicados[0]));
    }

    // Validar que todos los usos están en ids
    let noEncontrados = usos.filter(item => !ids.includes(item));
    if (noEncontrados.length > 0) {
        errores.push(new ErrorReglas("Regla no encontrada: " + noEncontrados[0]));
    }

    // Validacion de reglas huerfanas
    let huerfanos = [];

    let usoCounts = usos.reduce((countMap, uso) => {
        countMap[uso] = (countMap[uso] || 0) + 1;
        return countMap;
    }, {});

    ids.slice(1).forEach(id => {
        if (usoCounts[id] === 1) {
            huerfanos.push(id);
        }
    });

    if (huerfanos.length > 0) {
        errores.push(new ErrorReglas("Una o mas reglas huerfanas encontradas: " + huerfanos.join(', ')));
    }

    return prods;
}

producciones = _ id:identificador _ alias:(literales)? _ "=" _ expr:opciones (_";")? { 
    ids.push(id);
    return new n.Producciones(id, expr, alias);
}

// Producción principal que reconoce opciones dentro de paréntesis y operadores
opciones = expr:union rest:(_ "/" _ @union)* {
    // Crea una nueva instancia de Opciones con todas las expresiones unidas
    return new n.Opciones([expr, ...rest]);
}

union = expr:expresion rest:(_ @expresion !(_ literales? _ "="))* {
    // Une múltiples expresiones en una sola estructura de tipo Unión
    return new n.Union([expr, ...rest]);
}

expresion = label:$(etiqueta/varios)? _ expr:expresiones _ qty:$([?+*]/conteo)? {
    // Trata la expresión como una unidad que puede tener un operador aplicado
    return new n.Expresion(expr, label, qty);
}

etiqueta = ("@")? _ id:identificador _ ":" (varios)? // Manejo de etiquetas
varios = ("!"/"$"/"@"/"&") // Reconoce símbolos adicionales en etiquetas

expresiones =
    id:identificador {
        // Si se encuentra un identificador, se registra como una referencia
        usos.push(id); 
        return new n.Referencia(id);
    }
    / valor:$literales isCase:"i"? {
        // Maneja literales y les aplica el manejo de case insensitive si está especificado
        return new n.String(String(valor).replace(/['"]/g, ''), isCase);
    }
    / "(" _ op:opciones _ ")" qty:$([?+*]/conteo)? {
        // Maneja expresiones entre paréntesis
        // Se devuelve como Opciones dentro de una Expresión con operador (si aplica)
        const exprOpciones = new n.Opciones(op);
        return qty
            ? new n.Expresion(exprOpciones, null, qty) // Aplica operador si existe
            : exprOpciones; // Solo devuelve las opciones si no hay operador
    }
    / chars:clase isCase:"i"? {
        // Manejo de clases de caracteres como [a-z]
        return new n.Clase(chars, isCase);
    }
    / "." { 
        return new n.AnyCharacter(); // Reconoce cualquier carácter
    }
    / "!." { 
        return new n.NotAnyCharacter(); // Reconoce cualquier carácter excepto el punto
    }

conteo = "|" _ (numero / id:identificador) _ "|"
        / "|" _ (numero / id:identificador)? _ ".." _ (numero / id2:identificador)? _ "|"
        / "|" _ (numero / id:identificador)? _ "," _ opciones _ "|"
        / "|" _ (numero / id:identificador)? _ ".." _ (numero / id2:identificador)? _ "," _ opciones _ "|"

clase
  = "[" @contenidoClase+ "]"

contenidoClase
  = rangoInicial:$caracter "-" rangoFinal:$caracter {
    return new n.Rango(rangoInicial, rangoFinal);
  }
  / $caracter

caracter
  = [^\[\]\\]
  / "\\" .

//caracter
//    = [a-zA-Z0-9_ ] { return text()}

contenido
    = (corchete / texto)+

corchete
    = "[" contenido "]"

texto
    = [^\[\]]+

literales = '"' @stringDobleComilla* '"'
            / "'" @stringSimpleComilla* "'"

stringDobleComilla = !('"' / "\\" / finLinea) .
                    / "\\" escape
                    / continuacionLinea

stringSimpleComilla = !("'" / "\\" / finLinea) .
                    / "\\" escape
                    / continuacionLinea

continuacionLinea = "\\" secuenciaFinLinea

finLinea = [\n\r\u2028\u2029]

escape = "'"
        / '"'
        / "\\"
        / "b"
        / "f"
        / "n"
        / "r"
        / "t"
        / "v"
        / "u"

secuenciaFinLinea = "\r\n" / "\n" / "\r" / "\u2028" / "\u2029"

numero = [0-9]+

identificador = [_a-z]i[_a-z0-9]i* { return text() }

_ = (Comentarios /[ \t\n\r])*

Comentarios = 
    "//" [^\n]* 
    / "/*" (!"*/" .)* "*/"

