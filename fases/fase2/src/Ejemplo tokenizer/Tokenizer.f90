module tokenizer
    implicit none

    contains

   


    subroutine extractSpace(input, cursor, lexeme)
        character(len=*), intent(in) :: input
        integer, intent(inout) :: cursor
        character(len=:), allocatable :: lexeme
        integer :: start

        start = cursor

        do while (cursor <= len(input) .and. input(cursor:cursor) == ' ')
            cursor = cursor + 1
        end do

        allocate(character(len=cursor - start) :: lexeme)
        lexeme = "SPACE"
    end subroutine extractSpace

    logical function isAlpha(c)
        character(len=1), intent(in) :: c
        isAlpha = (c >= 'A' .and. c <= 'Z') .or. (c >= 'a' .and. c <= 'z')
    end function isAlpha

    logical function isDigit(c)
        character(len=1), intent(in) :: c
        isDigit = (c >= '0' .and. c <= '9')
    end function isDigit

    logical function isAlphaNum(c)
        character(len=1), intent(in) :: c
        isAlphaNum = isAlpha(c) .or. isDigit(c)
    end function isAlphaNum

end module tokenizer