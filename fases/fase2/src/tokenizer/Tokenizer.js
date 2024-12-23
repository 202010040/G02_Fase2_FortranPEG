

import Visitor from "../visitor/Visitor.js";
import {Clase, Rango} from '../visitor/CST.js';
import { generateCaracteres, KleeneCorchetes, TernariaLiterales } from "./utils.js";
import { CondicionalStrSencilla } from "./utils.js";
import { KleeneLiterales, PositivaLiterales  } from "./utils.js";

export default class Tokenizer extends Visitor {

    visitProducciones(node) {
		//console.log('Producciones: ', node) 
        return node.expr.accept(this);
    }
	visitOpciones(node) {
		//console.log('Opciones: ', node)
		return node.exprs.map(node => node.accept(this)).join('\n');
	}
	visitUnion(node) {
		//console.log('Expresion: ', node)
		return node.exprs.map(node => node.accept(this)).join('\n');
	}
	visitExpresion(node) {
		console.log('Expresion: ', node)
		// Validacion de Str sencillos
		if (node.expr instanceof String){
			switch (node.qty) {
			case "*":
				return KleeneLiterales(node.expr);
			case "+":
				return PositivaLiterales(node.expr);
			case "?":
				return TernariaLiterales(node.expr);
			default:
				return node.expr.accept(this);
			}	
		}
		if (node.expr instanceof Clase){
			switch (node.qty) {
			case "*":
				return KleeneCorchetes(node.expr);
			case "+":
				return PositivaLiterales(node.expr);
			case "?":
				return TernariaLiterales(node.expr);
			default:
				return node.expr.accept(this);
			}	
		}
		
		return node.expr.accept(this);

	}
	
	visitString(node) {
		//console.log('String: ', node)
		let condicional = CondicionalStrSencilla(node);

		return `
		if ( ${condicional} ) then
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