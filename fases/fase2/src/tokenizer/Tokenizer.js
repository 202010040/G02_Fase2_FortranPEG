import Visitor from "../visitor/Visitor.js";
import { Rango } from "../visitor/CST.js";
import { generateCaracteres } from "./utils.js";

export default class Tokenizer extends Visitor {
    visitProducciones(node) {
        return node.expr.accept(this);
    }

    visitOpciones(node) {
        return node.exprs.map(expr => expr.accept(this)).join("\n");
    }

    visitUnion(node) {
        return node.exprs.map(expr => expr.accept(this)).join("\n");
    }

    visitExpresion(node) {
        console.log("Expresion: ", node);
        const labelCode = node.label ? `! Etiqueta: ${node.label}` : "";
        const quantityCode = node.qty ? `! Cuantificador: ${node.qty}` : "";
        return `
        ${labelCode}
        ${quantityCode}
        ${node.expr.accept(this)}
        `;
    }

    visitEtiqueta(node) {
        console.log("Etiqueta: ", node);
        return `! Etiqueta: ${node.id}`;
    }

    visitVarios(node) {
        console.log("Varios: ", node);
        return `! Operador especial: ${node.symbol}`;
    }

    visitString(node) {
        console.log("String: ", node);
        const comparison = node.isCase
            ? `to_lower(input(cursor:cursor + ${node.val.length - 1})) == "${node.val.toLowerCase()}"`
            : `input(cursor:cursor + ${node.val.length - 1}) == "${node.val}"`;

        return `
        if (${comparison}) then
            allocate(character(len=${node.val.length}) :: lexeme)
            lexeme = input(cursor:cursor + ${node.val.length - 1})
            cursor = cursor + ${node.val.length}
            return
        end if
        `;
    }

    visitClase(node) {
		console.log("Clase: ", node);
		
		// Asegurarnos de que node.chars sea procesable como array o un único nodo
		const chars = Array.isArray(node.chars)
			? node.chars
			: [node.chars]; // Si no es array, convertir a array de un elemento
	
		const caracteresCode = generateCaracteres(
			chars.filter(char => typeof char === "string")
		);
		const rangosCode = chars
			.filter(char => char instanceof Rango)
			.map(range => range.accept(this))
			.join("\n");
	
		return `
			i = cursor
			${caracteresCode}
			${rangosCode}
		`;
	}
	

    visitRango(node) {
        return `
        if (input(i:i) >= "${node.rangoInicial}" .and. input(i:i) <= "${node.rangoFinal}") then
            lexeme = input(cursor:i)
            cursor = i + 1
            return
        end if
        `;
    }

    visitConteo(node) {
        console.log("Conteo: ", node);
        const min = node.min || "0";
        const max = node.max || "infinity";
        return `
        ! Validar rango entre ${min} y ${max}
        contador = 0
        do while (contador >= ${min} .and. contador <= ${max})
            ${node.opciones.accept(this)}
            contador = contador + 1
        end do
        `;
    }
}
