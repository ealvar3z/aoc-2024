program day07
    implicit none
    integer, parameter :: IK = selected_int_kind(18)  ! 64-bit
    integer(IK) :: total1, total2
    character(len=512) :: line
    integer :: ios

    total1 = 0_IK
    total2 = 0_IK

    do
        read(*,'(A)', iostat=ios) line
        if (ios /= 0) exit
        if (len_trim(line) == 0) cycle

        call process_line(trim(line), total1, total2)
    end do

    ! Print as full integers, no scientific notation
    write(*,'(I0)') total1
    write(*,'(I0)') total2

contains

    !----------------------------------------------------------
    ! Process one equation line: "T: a1 a2 a3 ..."
    !----------------------------------------------------------
    subroutine process_line(line, total1, total2)
        implicit none
        character(len=*), intent(in)  :: line
        integer(IK),      intent(inout) :: total1, total2

        integer(IK) :: target
        integer(IK), dimension(64) :: nums
        integer :: nnums
        logical :: ok1, ok2

        call parse_equation(line, target, nums, nnums)
        if (nnums <= 0) return

        ok1 = solvable_plus_mul(target, nums, nnums)
        if (ok1) total1 = total1 + target

        ok2 = solvable_with_concat(target, nums, nnums)
        if (ok2) total2 = total2 + target
    end subroutine process_line

    !----------------------------------------------------------
    ! Parse "190: 10 19" into:
    !   target = 190
    !   nums(1:nnums) = [10,19]
    !----------------------------------------------------------
    subroutine parse_equation(line_in, target, nums, nnums)
        implicit none
        character(len=*), intent(in) :: line_in
        integer(IK),      intent(out) :: target
        integer(IK),      intent(out) :: nums(:)
        integer,          intent(out) :: nnums

        character(len=:), allocatable :: line
        character(len=:), allocatable :: tok
        integer :: lenl, i, j, istart, iend
        integer :: ntok

        line = trim(line_in)
        lenl = len_trim(line)

        ! Replace ':' with space so tokens are all numeric
        do i = 1, lenl
            if (line(i:i) == ':') line(i:i) = ' '
        end do

        ntok  = 0
        nnums = 0

        i = 1
        do while (i <= lenl)
            ! Skip spaces
            do while (i <= lenl .and. line(i:i) == ' ')
                i = i + 1
            end do
            if (i > lenl) exit

            j = i
            do while (j <= lenl .and. line(j:j) /= ' ')
                j = j + 1
            end do

            istart = i
            iend   = j - 1

            if (iend >= istart) then
                tok = line(istart:iend)
                ntok = ntok + 1

                if (ntok == 1) then
                    read(tok, *) target
                else
                    if (ntok - 1 <= size(nums)) then
                        nnums = nnums + 1
                        read(tok, *) nums(nnums)
                    end if
                end if
            end if

            i = j + 1
        end do
    end subroutine parse_equation

    !----------------------------------------------------------
    ! Add value to arr(1:n) iff not already present.
    ! Simple O(n) check is fine for AoC.
    !----------------------------------------------------------
    subroutine add_unique(arr, n, val)
        implicit none
        integer(IK), intent(inout) :: arr(:)
        integer,     intent(inout) :: n
        integer(IK), intent(in)    :: val
        integer :: i

        do i = 1, n
            if (arr(i) == val) return
        end do

        n = n + 1
        if (n <= size(arr)) then
            arr(n) = val
        else
            ! In a pathological case, we could warn here.
            ! For AoC inputs, chosen size should be sufficient.
            n = size(arr)  ! clamp
        end if
    end subroutine add_unique

    !----------------------------------------------------------
    ! Part 1: DP with + and * only.
    !
    ! cur(1:ncur)   = reachable values after i-1 numbers
    ! nxt(1:nnxt)   = reachable values after i numbers
    ! We deduplicate with add_unique and prune > target.
    !----------------------------------------------------------
    logical function solvable_plus_mul(target, nums, nnums)
        implicit none
        integer(IK), intent(in) :: target
        integer(IK), intent(in) :: nums(:)
        integer,     intent(in) :: nnums

        integer, parameter :: MAX_STATES = 200000
        integer(IK), dimension(MAX_STATES) :: cur, nxt
        integer :: ncur, nnxt
        integer :: i, k
        integer(IK) :: v, a, s, p

        solvable_plus_mul = .false.
        if (nnums <= 0) return

        ! Start with a1 only
        cur(1) = nums(1)
        ncur   = 1

        if (nnums == 1) then
            solvable_plus_mul = (nums(1) == target)
            return
        end if

        do i = 2, nnums
            a    = nums(i)
            nnxt = 0

            do k = 1, ncur
                v = cur(k)

                ! v + a
                s = v + a
                if (s <= target) call add_unique(nxt, nnxt, s)

                ! v * a
                p = v * a
                if (p <= target) call add_unique(nxt, nnxt, p)
            end do

            if (nnxt == 0) then
                solvable_plus_mul = .false.
                return
            end if

            ncur = nnxt
            cur(1:ncur) = nxt(1:ncur)
        end do

        do k = 1, ncur
            if (cur(k) == target) then
                solvable_plus_mul = .true.
                return
            end if
        end do
    end function solvable_plus_mul

    !----------------------------------------------------------
    ! Concatenate v and a in base 10: v || a
    ! Example: v=12, a=345 => 12345
    !----------------------------------------------------------
    integer(IK) function concat_int(v, a)
        implicit none
        integer(IK), intent(in) :: v, a
        integer(IK) :: mul, x

        if (a == 0_IK) then
            concat_int = v * 10_IK
            return
        end if

        mul = 1_IK
        x   = a
        do while (x > 0_IK)
            mul = mul * 10_IK
            x   = x / 10_IK
        end do

        concat_int = v * mul + a
    end function concat_int

    !----------------------------------------------------------
    ! Part 2: DP with +, *, and concatenation.
    ! Same pattern as Part 1, just adds v || a branch.
    !----------------------------------------------------------
    logical function solvable_with_concat(target, nums, nnums)
        implicit none
        integer(IK), intent(in) :: target
        integer(IK), intent(in) :: nums(:)
        integer,     intent(in) :: nnums

        integer, parameter :: MAX_STATES = 200000
        integer(IK), dimension(MAX_STATES) :: cur, nxt
        integer :: ncur, nnxt
        integer :: i, k
        integer(IK) :: v, a, s, p, c

        solvable_with_concat = .false.
        if (nnums <= 0) return

        cur(1) = nums(1)
        ncur   = 1

        if (nnums == 1) then
            solvable_with_concat = (nums(1) == target)
            return
        end if

        do i = 2, nnums
            a    = nums(i)
            nnxt = 0

            do k = 1, ncur
                v = cur(k)

                ! v + a
                s = v + a
                if (s <= target) call add_unique(nxt, nnxt, s)

                ! v * a
                p = v * a
                if (p <= target) call add_unique(nxt, nnxt, p)

                ! v || a
                c = concat_int(v, a)
                if (c <= target) call add_unique(nxt, nnxt, c)
            end do

            if (nnxt == 0) then
                solvable_with_concat = .false.
                return
            end if

            ncur = nnxt
            cur(1:ncur) = nxt(1:ncur)
        end do

        do k = 1, ncur
            if (cur(k) == target) then
                solvable_with_concat = .true.
                return
            end if
        end do
    end function solvable_with_concat

end program day07
