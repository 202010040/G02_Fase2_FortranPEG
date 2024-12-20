{{
    // let identificadores = []

    // import { identificadores } from '../index.js'

    import { ids, usos} from '../index.js'
    import { ErrorReglas } from './error.js';
    import { errores } from '../index.js';

    import * as n from '../visitor/CST.js'




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

    return prods;
}

producciones = _ id:identificador _ alias:(literales)? _ "=" _ expr:opciones (_";")? { 
    ids.push(id)
    return new n.Producciones(id, expr, alias);
}

opciones = expr:union rest:(_ "/" _ @union)*{
    return new n.Opciones([expr, ...rest]); // Crea un arreglo con las expresiones
}

union = expr:expresion rest:(_ @expresion !(_ literales? _ "=") )* {
    return new n.Union([expr, ...rest]);
}

expresion  = label:$(etiqueta/varios)? _ expr:expresiones _ qty:$([?+*]/conteo)?{
    return new n.Expresion(expr, label, qty);
}

etiqueta = ("@")? _ id:identificador _ ":" (varios)?

varios = ("!"/"$"/"@"/"&")

expresiones  =  id:identificador { usos.push(id) }
                / valor:$literales isCase:"i"?{
                    return new n.String(valor, isCase); // El isCase se usa para validar si es case insensitive
                }
                / "(" _ opciones _ ")"
                / corchetes "i"?
                / "."
                / "!." 

conteo = "|" _ (numero / id:identificador) _ "|"
        / "|" _ (numero / id:identificador)? _ ".." _ (numero / id2:identificador)? _ "|"
        / "|" _ (numero / id:identificador)? _ "," _ opciones _ "|"
        / "|" _ (numero / id:identificador)? _ ".." _ (numero / id2:identificador)? _ "," _ opciones _ "|"

corchetes
    = "[" contenido:(rango / contenido)+ "]" {
        return `Entrada válida: [${input}]`;
    }

rango
    = inicio:caracter "-" fin:caracter {
        if (inicio.charCodeAt(0) > fin.charCodeAt(0)) {
            throw new Error(`Rango inválido: [${inicio}-${fin}]`);
        }
        return `${inicio}-${fin}`;
    }

caracter
    = [a-zA-Z0-9_ ] { return text()}

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

