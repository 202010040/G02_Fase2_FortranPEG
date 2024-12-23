
{{
    import { ids, usos} from '../index.js'
    import { ErrorReglas } from './error.js';
    import { errores } from '../index.js';
    import * as n from '../visitor/CST.js';
}}

gramatica = _ prods:producciones+ _ {

    // Validar duplicados en las reglas
    let duplicados = ids.filter((item, index) => ids.indexOf(item) !== index);
    if (duplicados.length > 0) {
        errores.push(new ErrorReglas("Regla duplicada: " + duplicados[0]));
    }

    // Validar que todos los usos están definidos en ids
    let noEncontrados = usos.filter(item => !ids.includes(item));
    if (noEncontrados.length > 0) {
        errores.push(new ErrorReglas("Regla no encontrada: " + noEncontrados[0]));
    }

    return new n.Gramatica(prods);
}

producciones = _ id:identificador _ alias:(literales)? _ "=" _ expr:opciones (_";")? { 
    ids.push(id);
    return new n.Producciones(id, expr, alias);
}

opciones = expr:union rest:(_ "/" _ @union)* {
    return new n.Opciones([expr, ...rest]);
}

union = expr:expresion rest:(_ @expresion !(_ literales? _ "="))* {
    return new n.Union([expr, ...rest]);
}

expresion = label:$(etiqueta/varios)? _ expr:expresiones _ qty:$([?+*]/conteo)? {
    return new n.Expresion(expr, label, qty);
}

etiqueta = "@"? _ id:identificador _ ":" EtiquetaVarios:(varios)? {
    return new n.Etiqueta(id, EtiquetaVarios);
}

varios = "!"/"$"/"@"/"&" {
    return new n.Varios(text());
}

expresiones  =  id:identificador {
        usos.push(id); 
        return new n.Identificador(id);
    }
    / valor:$literales isCase:"i"? {
        return new n.String(String(valor).replace(/['"]/g, ''), isCase);
    }
    / "(" _ op:opciones _ ")" {
        return op;
    }
    / ClassTemp:clase {
        return ClassTemp;
    }
    / "." {
        return new n.Punto();
    }
    / "!." {
        return new n.Fin();
    }

conteo = "|" _ (numero / id:identificador) _ "|" {
    return new n.Conteo(text());
}
    / "|" _ (numero / id:identificador)? _ ".." _ (numero / id2:identificador)? _ "|" {
        return new n.Conteo(text());
    }
    / "|" _ (numero / id:identificador)? _ "," _ opciones _ "|" {
        return new n.Conteo(text());
    }
    / "|" _ (numero / id:identificador)? _ ".." _ (numero / id2:identificador)? _ "," _ opciones _ "|" {
        return new n.Conteo(text());
    }

clase = "[" content:(contenidoClase+) "]" isCase:"i"? {
    return new n.Clase(content, isCase);
}

contenidoClase
  = rangoInicial:$caracter "-" rangoFinal:$caracter {
    return new n.Rango(rangoInicial, rangoFinal);
  }
  / $caracter {
    return new n.Caracter(text());
}

caracter = [^\[\]\\] / "\\" .

literales = '"' @stringDobleComilla* '"' 
    / "'" @stringSimpleComilla* "'" 

stringDobleComilla = !("\"" / "\\" / finLinea) .
                    / "\\" escape
                    / continuacionLinea

stringSimpleComilla = !("'" / "\\" / finLinea) .
                    / "\\" escape
                    / continuacionLinea

continuacionLinea = "\\" secuenciaFinLinea

finLinea = [\n\r\u2028\u2029]

escape = "'" / '"' / "\\" / "b" / "f" / "n" / "r" / "t" / "v" / "u"

secuenciaFinLinea = "\r\n" / "\n" / "\r" / "\u2028" / "\u2029"

numero = [0-9]+

identificador = [_a-z]i[_a-z0-9]i* {
    return text();
}

_ = (Comentarios /[ \t\n\r])*

Comentarios = 
    "//" [^\n]* 
    / "/*" (!"*/" .)* "*/"
