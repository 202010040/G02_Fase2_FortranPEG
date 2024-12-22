import Visitor from "../visitor/Visitor.js";
import {Rango} from '../visitor/CST.js';
import { generateCaracteres } from "./utils.js";

export default class Tokenizer extends Visitor {

    visitProducciones(node) {
        return node.expr.accept(this);
    }
	visitOpciones(node) {
		return node.exprs.map(node => node.accept(this)).join('\n');
	}
	visitUnion(node) {
		return node.exprs.map(node => node.accept(this)).join('\n');
	}
	visitExpresion(node) {
		console.log('Expresion: ', node)
		return node.expr.accept(this);
	}
	
	visitString(node) {
		console.log('String: ', node)
		if (node.isCase) {
			return `
		if (to_lower(input(cursor:cursor + ${node.val.length - 1})) == "${node.val.toLowerCase()}") then
			allocate(character(len=${node.val.length}) :: lexeme)
			lexeme = input(cursor:cursor + ${node.val.length - 1})
			cursor = cursor + ${node.val.length}
			return
		end if
			`;
		}
	
		return `
		if (input(cursor:cursor + ${node.val.length - 1}) == "${node.val}") then
			allocate(character(len=${node.val.length}) :: lexeme)
			lexeme = input(cursor:cursor + ${node.val.length - 1})
			cursor = cursor + ${node.val.length}
			return
		end if
		`;
	}
	
	
	visitClase(node){
		console.log('Clase', node)
		return `
		i = cursor
		${generateCaracteres(
			node.chars.filter((node) => typeof node === 'string')
		)}
		${
			node.chars
				.filter((node)  => node instanceof Rango )
				.map((range) => range.accept(this))
				.join('\n')
		}
		`
	}

	visitRango(node){
		return `
		if (input(i:i) >= "${node.rangoInicial}" .and. input(i:i) <= "${node.rangoFinal}") then
			lexeme = input(cursor:i)
			cursor = i + 1
			return
		end if
			`;
	}
}