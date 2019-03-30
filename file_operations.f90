module file_operations
    implicit none



    contains



    !
    ! Subroutine for checking if the log file exists or not
    ! If exists, open as a file to append
    ! If doesn't exists, open as a new file
    !
    ! Mayank Sharma (@UC) - 24/11/18
    !
    !---------------------------------------------------------------------------
    subroutine log_file_exists(log_file, nopen, file_open, initial)
        
        character(len = :), allocatable,    intent(inout)   :: log_file
        integer,                            intent(inout)   :: nopen
        logical,                            intent(inout)   :: file_open
        logical,    optional,               intent(in)      :: initial

        ! Local variables
        logical             :: exist
        integer             :: ierr


        log_file    = 'T-Blade3_run.log'
        nopen       = 101

        inquire(file = log_file, exist=exist)
        if (exist) then
            if (present(initial) .and. initial .eqv. .true.) then
                open(nopen, file = log_file, status = 'old', action = 'write')
            else 
                open(nopen, file = log_file, status = 'old', iostat = ierr, position = 'append', action = 'write')
            end if
        else
            open(nopen, file = log_file, status = 'new', iostat = ierr, action = 'write')
        end if

        if (ierr == 0) then
            file_open = .true.  
        else
            file_open = .false.
        end if


    end subroutine log_file_exists
    !---------------------------------------------------------------------------



    !
    ! Close log file if it is open
    !
    ! Mayank Sharma (@UC) - 24/11/18
    !
    !---------------------------------------------------------------------------
    subroutine close_log_file(nopen, file_open)

        integer,        intent(in)      :: nopen
        logical,        intent(in)      :: file_open


        ! If the log file is open, close it
        if (file_open) close(nopen)


    end subroutine close_log_file
    !---------------------------------------------------------------------------



    !
    ! Subroutine for checking if the input log file exists or not
    ! If exists, open as a file to append
    ! If doesn't exist, open as a new file
    !
    ! Mayank Sharma (@UC) - 9/12/18
    !
    !---------------------------------------------------------------------------
    subroutine open_maininput_log_file(input_file, nopen, file_open)
        
        character(*),                   intent(in)          :: input_file
        integer,                        intent(inout)       :: nopen
        logical,                        intent(inout)       :: file_open

        ! Local variables
        character(50)   :: maininput_log_file
        logical         :: exist
        integer         :: ierr, index1


        nopen               = 102
        index1              = index(input_file, 'dat')
        maininput_log_file  = input_file(:index1 - 1)//'log'

        inquire(file = trim(maininput_log_file), exist=exist)
        if (exist) then
            open(nopen, file = trim(maininput_log_file), status = 'old', iostat = ierr, action = 'write')
        else
            open(nopen, file = trim(maininput_log_file), status = 'new', iostat = ierr, action = 'write')
        end if

        if (ierr == 0) then
            file_open = .true.
        else
            file_open = .false.
        end if


    end subroutine open_maininput_log_file
    !---------------------------------------------------------------------------



    !
    ! Close input log file if open
    !
    ! Mayank Sharma (@UC) - 10/12/18
    !
    !---------------------------------------------------------------------------
    subroutine close_maininput_log_file(nopen, file_open)

        integer,                    intent(in)              :: nopen
        logical,                    intent(in)              :: file_open

        ! If the file is open, close it
        if (file_open) close(nopen)


    end subroutine close_maininput_log_file
    !---------------------------------------------------------------------------



    !
    ! Subroutine for checking if the input log file exists or not
    ! If exists, open as a file to append
    ! If doesn't exist, open as a new file
    !
    ! Mayank Sharma (@UC) - 9/12/18
    !
    !---------------------------------------------------------------------------
    subroutine open_auxinput_log_file(input_file, nopen, file_open)
        
        character(*),               intent(in)              :: input_file
        integer,                    intent(inout)           :: nopen
        logical,                    intent(inout)           :: file_open
        
        ! Local variables
        character(50)       :: auxinput_log_file
        logical             :: exist
        integer             :: ierr, index1
        
        
        nopen               = 102
        index1              = index(input_file, 'dat')
        auxinput_log_file   = input_file(:index1 - 1)//'log'
        
        inquire(file = trim(auxinput_log_file), exist=exist)
        if (exist) then
            open(nopen, file = trim(auxinput_log_file), status = 'old', iostat = ierr, action = 'write')
        else
            open(nopen, file = trim(auxinput_log_file), status = 'new', iostat = ierr, action = 'write')
        end if

        if (ierr == 0) then
            file_open = .true.
        else
            file_open = .false.
        end if


    end subroutine open_auxinput_log_file
    !---------------------------------------------------------------------------



    !
    ! Close input log file if open
    !
    ! Mayank Sharma (@UC) - 10/12/18
    !
    !---------------------------------------------------------------------------
    subroutine close_auxinput_log_file(nopen, file_open)

        integer,                intent(in)              :: nopen
        logical,                intent(in)              :: file_open


        ! If the file is open, close it
        if (file_open) close(nopen)


    end subroutine close_auxinput_log_file
    !---------------------------------------------------------------------------



    !
    ! Write meanline u,v data to a file
    !
    !---------------------------------------------------------------------------
    subroutine meanline_u_v_file(np,sec,u,camber,slope)

        integer,                intent(in)              :: np
        character(*),           intent(in)              :: sec
        real,                   intent(in)              :: u(np)
        real,                   intent(in)              :: camber(np)
        real,                   intent(in)              :: slope(np)

        ! Logical
        character(:),   allocatable                     :: meanline_file
        integer                                         :: nopen = 831, i
        logical                                         :: exist


        ! 
        ! Inquire if the meanline (u,v) file exists
        ! If it exists, overwrite 
        !
        meanline_file   = 'meanline_uv.'//trim(adjustl(sec))//'.dat'
        inquire(file = meanline_file, exist=exist)
        if (exist) then
            open(nopen, file = trim(meanline_file), status = 'old', action = 'write', form = 'formatted')
        else
            open(nopen, file = trim(meanline_file), status = 'new', action = 'write', form = 'formatted')
        end if
        
        do i = 1,np
            write(nopen,'(3F30.16)') u(i), camber(i), slope(i)
        end do
        
        close(nopen)


    end subroutine meanline_u_v_file
    !---------------------------------------------------------------------------
    
    
    
    !
    ! Write 2D array in matrix form to a file
    ! Specified for (x,y) grid coordinates 
    !
    !---------------------------------------------------------------------------
    subroutine file_write_matrix(fname,X,Y,nx,ny)
    
        character(32),          intent(in)              :: fname
        integer,                intent(in)              :: nx
        integer,                intent(in)              :: ny
        real,                   intent(in)              :: X(nx,ny)
        real,                   intent(in)              :: Y(nx,ny)

        ! Local variables
        integer                                         :: i, funit = 1


        !
        ! Open specified file and start writing to file
        !
        open(funit, file = fname, status = 'unknown')
        
        write(funit,*) nx, ny
        
        ! Write x coordinates
        write(funit,*) 'X coordinates'
        do i = 1,nx
            write(funit,*) X(i,:)
        end do
        write(funit,*) ''

        ! Write y coordinates
        write(funit,*) 'Y coordinates'
        do i = 1,nx
            write(funit,*) Y(i,:)
        end do
        
        close(funit)


    end subroutine file_write_matrix
    !---------------------------------------------------------------------------
    
    
    
    !
    ! Write 1D arrays to a file
    !
    !---------------------------------------------------------------------------
    subroutine file_write_1D(fname,X,Y,nx)
    
        character(32),          intent(in)              :: fname
        integer,                intent(in)              :: nx
        real,                   intent(in)              :: X(nx)
        real,                   intent(in)              :: Y(nx)

        ! Local variables
        integer                                         :: i, funit = 1


        !
        ! Open specified file and start writing to file
        !
        open(funit, file = fname, status = 'unknown')
        do i = 1,nx
            write(funit,'(2F20.16)') X(i), Y(i)
        end do
        close(funit)


    end subroutine file_write_1D
    !---------------------------------------------------------------------------



















end module file_operations
