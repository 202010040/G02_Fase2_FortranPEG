{{
    // let identificadores = []

    // import { identificadores } from '../index.js'

    import { ids, usos} from '../index.js'
    import { ErrorReglas } from './error.js';
    import { errores } from '../index.js';


    // Función para generar el módulo Fortran automáticamente
function generarModuloFortran() {
    // Crear el contenido del módulo
    let moduloFortran = `module parser\n`;
    moduloFortran += `  implicit none\n`;
    moduloFortran += `contains\n`;
    moduloFortran += `  function nextsym() result(token_name)\n`;
    moduloFortran += `    implicit none\n`;
    moduloFortran += `    character(len=*) :: token_name\n`;
    moduloFortran += `    ! Implementación del tokenizador aquí\n`;
    moduloFortran += `  end function nextsym\n`;
    moduloFortran += `end module parser\n`;

    // Guardar o servir el archivo generado
    guardarModulo(moduloFortran);
}

// Guardar o servir el módulo generado
function guardarModulo(moduloFortran) {
    const blob = new Blob([moduloFortran], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'parser.f90';
    link.click();
    URL.revokeObjectURL(url);
}

// Evento para el botón de descarga
function descargarModuloFortran() {
    generarModuloFortran();
}


}}

gramatica = _ producciones+ _ {

    let duplicados = ids.filter((item, index) => ids.indexOf(item) !== index);
    if (duplicados.length > 0) {
        errores.push(new ErrorReglas("Regla duplicada: " + duplicados[0]));
    }

    // Validar que todos los usos están en ids
    let noEncontrados = usos.filter(item => !ids.includes(item));
    if (noEncontrados.length > 0) {
        errores.push(new ErrorReglas("Regla no encontrada: " + noEncontrados[0]));
    }
}

producciones = _ id:identificador _ (literales)? _ "=" _ opciones (_";")? { ids.push(id) }

opciones = union (_ "/" _ union)*

union = expresion (_ expresion !(_ literales? _ "=") )*

expresion  = (etiqueta/varios)? _ expresiones _ ([?+*]/conteo)?

etiqueta = ("@")? _ id:identificador _ ":" (varios)?

varios = ("!"/"$"/"@"/"&")

expresiones  =  id:identificador { usos.push(id) }
                / literales "i"?
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

literales = '"' stringDobleComilla* '"'
            / "'" stringSimpleComilla* "'"

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

