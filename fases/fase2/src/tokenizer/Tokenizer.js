import Visitor from "../visitor/Visitor.js";
import { Clase, Rango } from "../visitor/CST.js";
import { generateCaracteres, KleeneCorchetes, PositivaCorchetes, TernariaCorchetes, TernariaLiterales, CondicionalCorchete } from "./utils.js";
import { CondicionalStrSencilla } from "./utils.js";
import { KleeneLiterales, PositivaLiterales } from "./utils.js";

export default class Tokenizer extends Visitor {
    visitProducciones(node) {
        return node.expr.accept(this);
    }

    visitOpciones(node) {
        return node.exprs.map((node) => node.accept(this)).join("\n");
    }

    visitUnion(node) {
        return node.exprs.map((node) => node.accept(this)).join("\n");
    }

    visitExpresion(node) {
        if (node.expr instanceof String) {
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
        if (node.expr instanceof Clase) {
            switch (node.qty) {
                case "*":
                    return KleeneCorchetes(node.expr);
                case "+":
                    return PositivaCorchetes(node.expr);
                case "?":
                    return TernariaCorchetes(node.expr);
                default:
                    return node.expr.accept(this);
            }
        }

        return node.expr.accept(this);
    }

    visitString(node) {
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

    visitClase(node) {
        return `
        i = cursor
        ${generateCaracteres(
            node.chars.filter((node) => typeof node === "string")
        )}
        ${
            node.chars
                .filter((node) => node instanceof Rango)
                .map((range) => range.accept(this))
                .join("\n")
        }
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

    visitPatron(node) {
		// Manejo específico del patrón [a-z][A-Z]
		if (node.type === "range" && node.pattern === "[a-z][A-Z]") {
			const condicionalAtoZ = CondicionalCorchete({
				chars: [{ rangoInicial: "a", rangoFinal: "z" }],
			});
			const condicionalUpperAtoZ = CondicionalCorchete({
				chars: [{ rangoInicial: "A", rangoFinal: "Z" }],
			});
	
			return `
			! Manejo del patrón [a-z][A-Z] repetido
			ejecuta_ciclo = .true.
			allocate(character(len=0) :: lexeme_accumulated)
			do while (ejecuta_ciclo)
				! Verificar si el siguiente carácter está en el rango [a-z]
				if (${condicionalAtoZ}) then
					call appendCharacter(lexeme_accumulated, input(cursor:cursor))
					cursor = cursor + 1
				else
					exit
				end if
	
				! Verificar si el siguiente carácter está en el rango [A-Z]
				if (${condicionalUpperAtoZ}) then
					call appendCharacter(lexeme_accumulated, input(cursor:cursor))
					cursor = cursor + 1
				else
					exit
				end if
			end do
	
			if (len(lexeme_accumulated) > 0) then
				allocate(character(len=len(lexeme_accumulated)) :: lexeme)
				lexeme = lexeme_accumulated
				return
			end if
			`;
		}
	
		// Manejo genérico para otros patrones
		return `
		! Manejo de patrones no reconocidos
		print *, "Patrón no reconocido en col ", cursor
		allocate(character(len=5) :: lexeme)
		lexeme = "ERROR"
		cursor = cursor + 1
		`;
	}
	

    visitDefault(node) {
        return `
        ! Manejo de caracteres no reconocidos
        print *, "error lexico en col ", cursor, ', "' // input(cursor:cursor) // '"'
        allocate(character(len=5) :: lexeme)
        lexeme = "ERROR"
        cursor = cursor + 1
        `;
    }
}