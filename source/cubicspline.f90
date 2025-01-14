!
! Subroutine to create a cubic B-spline (xbs,ybs) with nspline points
! using control points
!
! Input parameters: ncp     - number of B-spline control points
!                   xcp     - x coordinates of control points
!                   ycp     - y coordinates of control points
!                   
!-----------------------------------------------------------------------------------
subroutine cubicspline(ncp,xcp,ycp,xbs,ybs,y_spl_end,nspline,xc,yc,ncp1, &
                       diff,dcpall)
    implicit none

    ! Local constants
    integer,    parameter                   :: np = 50, nx = 500, nax = 100

    ! Input parameters
    integer,                intent(in)      :: ncp
    real,                   intent(inout)   :: xcp(ncp), ycp(ncp), xbs(nx), ybs(nx), &
                                               y_spl_end(ncp)
    integer,                intent(inout)   :: nspline
    real,                   intent(inout)   :: xc(ncp + 2), yc(ncp + 2)
    integer,                intent(inout)   :: ncp1
    logical,                intent(in)      :: diff
    real,                   intent(inout)   :: dcpall(ncp, ncp + 2)

    ! Local variables
    integer                                 :: i, j, k, nbsp
    real                                    :: xs(nx), ys(nx)
    real                                    :: t(nx), T1(nx), T2(nx), T3(nx), T4(nx)


    !
    ! Computation of B-spline parameter values and basis 
    ! functions for all cubic B-spline points
    !
    do i = 1, np
        t(i)                = (1.0/(np-1))*(i-1)
        T1(i)               = ((-t(i)**3) + (3*t(i)**2) - (3*t(i)) + 1)/6
        T2(i)               = ((3*t(i)**3) - (6*t(i)**2) + 4)/6
        T3(i)               = ((-3*t(i)**3) + (3*t(i)**2) + (3*t(i)) + 1)/6
        T4(i)               = (t(i)**3)/6
    end do



    !
    ! Fixing start and end points as collocation points
    ! Start point: Considering the 1st CP as the mid point of the 2nd CP and the start point
    !
    xc(1)                   = 2*xcp(1) - xcp(2)
    yc(1)                   = 2*ycp(1) - ycp(2)
    
    ! End point: Considering the last CP as the mid point of the end point and the penultimate CP 
    xc(ncp + 2)             = 2*xcp(ncp) - xcp(ncp - 1)
    yc(ncp + 2)             = 2*ycp(ncp) - ycp(ncp - 1)

    do i = 1, ncp
        xc(i + 1)           = xcp(i)
        yc(i + 1)           = ycp(i)
    end do

    ! Include the start and end points in number of control points
    ncp1                    = ncp + 2 
    nbsp                    = (np)*(ncp1 - 3)




    !
    ! Compute derivatives of all control points
    ! with respect to themselves and store in an array
    !
    dcpall                  = 0.0

    ! Derivatives related to start point
    dcpall(1, 1)            = 2.0
    dcpall(2, 1)            = -1.0

    ! Derivatives related to end point
    dcpall(ncp - 1,ncp1)    = -1.0
    dcpall(ncp, ncp1)       = 2.0

    ! Derivative of a control point wrt itself
    do i = 1, ncp
        dcpall(i, i + 1)    = 1.0
    end do



    !
    ! Constructing cubic B-spline curve using 4 points P0(x0,y0), P1(x1,y1), P2(x2,y2), P3(x3,y3) as
    ! B(t) =(((1-t)^3)*P0) + (3*((1-t)^2)*t*P1) + (3*(1-t)*(t^2)*P2) + ((t^3)*P3); 0 <= t <= 1
    ! 
    do j = 1, ncp1 - 3

        do i = 1, np

            xs(i)           = (xc(j)*T1(i)) + (xc(j + 1)*T2(i)) + &
                              (xc(j + 2)*T3(i)) + (xc(j + 3)*T4(i))
            ys(i)           = (yc(j)*T1(i)) + (yc(j + 1)*T2(i)) + &
                              (yc(j + 2)*T3(i)) + (yc(j + 3)*T4(i))

            ! Storing B-spline points in a contiguous 1D array
            k               = i + (np)*(j - 1)
            xbs(k)          = xs(i)
            ybs(k)          = ys(i)

        end do  ! i = 1, np

       !picking up the endpoints of each spline for Newton interpolation
        if (j == 1) then
            y_spl_end(1)    = ys(1)
        end if
        y_spl_end(j + 1)    = ys(np)

    end do  ! j = 1, ncp1 - 3

    nspline                 = nbsp


end subroutine cubicspline
!-----------------------------------------------------------------------------------






!
! Subroutine to compute the point of intersection of a B-spline and a line segment
!
! Input parameters: ncp     - number of spline control points
!                   xcp     - x coordinates of control points
!                   ycp     - y coordinates of control points
!                   na      - number of spanwise sections
!                   xin     - x (or y) coordinate of the intersection point
!                   xbs     - x coordinates of spline points
!                   ybs     - y coordinates of spline points
!
!-----------------------------------------------------------------------------------
subroutine cubicbspline_intersec(ncp,xcp,ycp,na,xin,yout,xbs,ybs,y_spl_end,diff, &
                                 segment_info,spline_params,cp_pos)
    implicit none

    ! Local constants
    integer,    parameter                   :: np = 50, nx = 500

    ! Input parameters
    integer,                intent(in)      :: ncp
    real,                   intent(in)      :: xcp(ncp), ycp(ncp)
    integer,                intent(in)      :: na
    real,                   intent(in)      :: xin(na)
    real,                   intent(inout)   :: yout(na)
    real,                   intent(in)      :: xbs(np * (ncp - 3)), ybs(np * (ncp - 3))
    real,                   intent(in)      :: y_spl_end(ncp - 2)
    logical,                intent(in)      :: diff
    integer,                intent(inout)   :: segment_info(na, 4)  ! Arrays to store B-spline coefficients and
    real,                   intent(inout)   :: spline_params(na)    ! spline parameter values for each y_out
    integer,                intent(inout)   :: cp_pos(na, ncp - 2)


    ! Local variables
    integer                                 :: i, j, k
    real                                    :: d1_B11, B11, d1_B22, B22, d1_B33, B33, &
                                               d1_B44, B44, ys_0, d1_ys_0, tt_0, tt


    !
    ! Initialize differentiation arrays
    !
    segment_info                = 0
    spline_params               = 0.0



    !
    ! Newton method to find yout corresponding to xin
    !
    ! for 1st control point
    yout(1)                     = xbs(1)

    ! for last control point
    yout(na)                    = xbs(np * (ncp - 3))

    ! Set segment information and spline parameter
    ! values for first and last spanwise values
    if (diff) then
        segment_info(1, :)      = [1, 2, 3, 4]
        spline_params(1)        = 0.0
        segment_info(na, :)     = [ncp - 3, ncp - 2, ncp - 1, ncp]
        spline_params(na)       = 1.0
    end if


    do j = 1, ncp - 3
        do i = 2, na - 1

            if ((xin(i) > y_spl_end(j)) .and. (xin(i) < y_spl_end(j + 1))) then

                ! Initial guess
                tt_0        = 0.3

                do k = 1, 10

                    ! Basis functions
                    B11     = ((-tt_0**3) + (3*tt_0**2) - (3*tt_0) + 1)/6
                    B22     = ((3*tt_0**3) - (6*tt_0**2) + 4)/6
                    B33     = ((-3*tt_0**3) + (3*tt_0**2) + (3*tt_0) + 1)/6
                    B44     = (tt_0**3)/6

                    ! First derivatives of basis functions
                    d1_B11  = ((-3*tt_0**2) + (6*tt_0) - (3))/6
                    d1_B22  = ((9*tt_0**2) - (12*tt_0))/6
                    d1_B33  = ((-9*tt_0**2) + (6*tt_0) + (3))/6
                    d1_B44  = (3*tt_0**2)/6

                    ! Spline point computation
                    ys_0    = (ycp(j)*B11) + (ycp(j + 1)*B22) + (ycp(j + 2)*B33) + (ycp(j + 3)*B44)

                    ! Spline point first derivative computation
                    d1_ys_0 = (ycp(j)*d1_B11) + (ycp(j + 1)*d1_B22) + (ycp(j + 2)*d1_B33) + (ycp(j + 3)*d1_B44)

                    ! Newton's interpolation
                    tt      = tt_0 + (xin(i) - ys_0)/d1_ys_0

                    if (abs(tt - tt_0) < 1e-16) then
                        B11 = ((-tt**3) + (3*tt**2) - (3*tt) + 1)/6
                        B22 = ((3*tt**3) - (6*tt**2) + 4)/6
                        B33 = ((-3*tt**3) + (3*tt**2) + (3*tt) + 1)/6
                        B44 = (tt**3)/6
                        goto 20
                    end if  ! abs(tt - tt_0)

                    ! Set tt_0 for next iteration
                    tt_0    = tt

                end do  ! k = 1, 10

20              yout(i)     = (xcp(j)*B11) + (xcp(j + 1)*B22) + (xcp(j + 2)*B33) + (xcp(j + 3)*B44)

                ! Store segment information and spline parameter
                ! value for each yout(i)
                if (diff) then
                    segment_info(i,:) = [j, j + 1, j + 2, j + 3]
                    spline_params(i)  = tt
                end if

            end if  ! xin(i)

        end do ! i = 2, na - 1
    end do    ! j = 1, ncp - 3


    ! Fill cp_pos array
    cp_pos = 0
    if (diff) then

        do i = 1, na
            do j = 2, ncp - 1
                do k = 1, 4

                    if (j == segment_info(i, k)) then
                        cp_pos(i, j - 1)    = k
                    end if

                end do  ! k
            end do  ! j
        end do  ! i

    end if  ! diff


end subroutine cubicbspline_intersec
!-----------------------------------------------------------------------------------






!
! UNUSED SUBROUTINES
!
!-----------------------------------------------------------------------------------
!subroutine curv_line_inters(xbs,ybs,nspline,xin,yout,nspan)
!! Calculates the intersection point between the line and the curve
!! input: curve points (xbs,ybs), no. of curve points (nspline),xin from the line
!!output: yout for the line on the curve.
!use errors
!implicit none
!
!integer ii,j, nspline, nx,nspan
!parameter(nx=1000)
!real*8 xbs(nspline),ybs(nspline), xin(nspan), yout(nspan)
!real*8 min, max, xmax, xmin, xint
!character(:),   allocatable :: error_msg, warning_msg, warning_arg, dev_msg
!!print*,'xin:',xin
!
!! Initialize warning_arg
!warning_arg = ''
!
!do j = 1, nspan
! do ii = 1, nspline-1
!  xint = xbs(ii+1) + (ybs(ii+1) - xin(j))*(((xbs(ii) - xbs(ii+1))/(ybs(ii+1) - ybs(ii))))
!!  print*,'xint',xint
!  xmax = max(xbs(ii),xbs(ii+1))
!  xmin = min(xbs(ii),xbs(ii+1))
!!  print*,xmin,xmax
!!  xmin1 = xmin(i)
!!  xmax1 = xmax(i)
!  if (xint.ge.xmin.and.xint.le.xmax)then
!     yout(j) = xint
!  elseif(xint.eq.0.)then
!     error_msg      = 'Curve-line intersection point was not found'
!     write(warning_arg, '(f20.16)') xint
!     warning_msg    = 'xint = '//warning_arg 
!     dev_msg        = 'Check subroutine curv_line_inters in cubicspline.f90'
!     call fatal_error(error_msg, warning_msg, dev_msg)
!  end if
! enddo
!!write(*,*)
!! Forcing Start and End points to be the same as control points at start and end.
!! if(j.eq.1)then
! ! yout(j) = xbs(1)
!! elseif(j.eq.nspan)then
! ! yout(j) = xbs(nspline)
!! endif 
!! Forcing only the end point to be the same as the point on the curve
!!if(j.eq.nspan) yout(j) = xbs(nspline)
!!print*,xmin,xmax
!! print*,yout(j)
!enddo
!return
!end subroutine curv_line_inters
!
!
!subroutine curvline_intersec(xcp,ycp,ncp,xinarray,youtarray,na,ia)
!! Curve line intersection procedure using Newton-Raphson method....Kiran Siddappaji 3/29/13
!!Curve: F(y) (or F(x)). Line y = c or x = c.
!! The root(s) of the F(y) - y_line (or F(x) - x_line) is the intersection point.
!!inputs:
!! (xcp,ycp): control points 
!! ncp: no. of control points
!! (xbs,ybs): spline points
!! nbs: no. of spline points
!!xin: x (or y) coordinate of the intersection point.
!!outputs:
!!yout: y (or x) coordinate of the intersection point.
!
!implicit none
!
!integer i,j,ia,na,ncp,nx,ncp1
!
!parameter(nx = 500)
!
!real*8 xcp(ncp),ycp(ncp),xinarray(na),youtarray(na)
!real*8 xcp1(50),ycp1(50)
!real*8 xin,yout,yp2,yp1
!!real*8 xbsd(nbs),ybsd(nbs) ! displaced spline coordinates
!real*8 xc(4),yc(4) ! 4 control points for a single spline segment
!real*8 k1,k2,k3,k4,a1,a2,a3,a4,t(nx),tfinal,eps
!real*8 func(nx),dfunc(nx) ! f(t) and f'(t)
!real*8 gfunc
!
!! Initializing xc and tfinal
!xc     = 0.0
!yc     = 0.0
!tfinal = 0.0
!
!
!xin = xinarray(ia)
!! Making the start and end points as collocation points----
!! Start point: Considering the 1st CP as the mid point of the 2nd CP and the start point----------
!xcp1(1) = 2*xcp(1) - xcp(2)
!ycp1(1) = 2*ycp(1) - ycp(2)
!! End point: Considering the last CP as the mid point of the end point and the penultimate CP ----
!xcp1(ncp+2) = 2*xcp(ncp) - xcp(ncp-1)
!ycp1(ncp+2) = 2*ycp(ncp) - ycp(ncp-1)
!do i=1,ncp
!  xcp1(i+1) = xcp(i)
!  ycp1(i+1) = ycp(i)
!enddo
!!print*,'Old  control points',ncp
!ncp1 = ncp+2 ! adding the first and last control points to the set of CPs.
!!print*,'New control points',ncp1
!!do i =1,ncp1
!! print*,ycp1(i),xcp1(i)
!!enddo
!!write(*,*) 
!!print*,'xin:',xin
!! Checking which spline segment is being intersected by a particular line.
!! Logic: If the y_line (or x_line) lies between (i-1)th and ith ycp (or xcp), where i >= 4 then....
!!....... the spline segment controlled by (i-3)th and ith control points is being intersected by the line.
!! The control points have to be displaced by y_line (or x_line) 
! j = 0
! do i = 2, ncp1! check if y_line (or x_line) lies between the last 2 control points of a spline segment
!  yp1 = ycp1(i-1) 
!  yp2 = ycp1(i) 
!!  print*,'yp1,yp2:',yp1,yp2
!  if((yp2.ge.xin.and.yp1.le.xin).and.j.eq.0)j = i  
! ! if(i.eq.ncp)j = ncp 
! enddo
! !var2 = ycp(ncp -1)
! !if(xin.ge.var2)j = ncp
! ! print*,'j:',j
!!  goto 10 !skipping this block
!! Obtaining the 4 appropriate YCPs for that spline segment
!if(j.ne.0.and.j.le.4)then
! yc(1) = ycp1(1) !- xin
! yc(2) = ycp1(2) !- xin
! yc(3) = ycp1(3) !- xin
! yc(4) = ycp1(4) !- xin
!! print*,'Spline curve segment being intersected by ',xin,' is',1
!elseif(j.ge.4)then
! yc(1) = ycp1(j-3) !- xin
! yc(2) = ycp1(j-2) !- xin
! yc(3) = ycp1(j-1) !- xin
! yc(4) = ycp1(j)   !- xin
!! print*,'Spline curve segment being intersected by ',xin,' is',j-3
!endif
!
!! Creating the F_y(t) - y_line (or F_x(t) - x_line) function for the spline segment being intersected using the appropriate control points.
!!  F(t) = k1(t^3) + k2(t^2) + k3(t) + k4 - yline ; F(t) = F_y(t) - yline (or F_x(t) - xline)
!!  F'(t) = 3k1(t^2) + 2k2(t) + k3
!! if F(y) then xin is yline and if F(x) then xin is xline.
!! k1 = (1/6)*( -YCP1 + 3YCP2 - 3YCP3 + YCP4)
!! k2 = (1/6)*( 3YCP1 - 6YCP2 + 3YCP3)
!! k3 = (1/6)*(-3YCP1 + 3YCP3)
!! k4 = (1/6)*(  YCP1 + 4YCP2 + YCP3) - yline
!!---------------
!! Forming the cubic equation F(t) in t
! k1 = ( -yc(1)  + (3*yc(2)) - (3*yc(3)) + yc(4))/6
! k2 = ( (3*yc(1)) - (6*yc(2)) + (3*yc(3)))/6
! k3 = ((-3*yc(1)) + (3*yc(3)))/6
! k4 = (  yc(1)  + (4*yc(2)) + yc(3))/6  - xin
!!-------------------------------
!! Newton -Raphson method for finding t
!! t(n) = t(n-1) - F(t(n-1))/F'(t(n-1))
!! eps = abs(t(n) - t(n-1))
!! intitial guess:t0
!  t(1) = 0.3  
! do i = 2, 10
! ! Function and it's derivative w.r.t t 
!  func(i-1)  =   k1*t(i-1)**3 + k2*t(i-1)**2 + k3*t(i-1) + k4 
!  dfunc(i-1) = 3*k1*t(i-1)**2 + 2*k2*t(i-1)  + k3
!  t(i) = t(i-1) - func(i-1)/dfunc(i-1)
!  eps = abs(func(i-1)/dfunc(i-1))
!!  print*,'Iteration',i,'diff',eps
!  if(eps.le.1.0E-5)then
!   tfinal = t(i)
! !  print*,'Iteration',i,'tfinal',tfinal
! !  print*,'Solution converged using Newton-Raphson method...'
!   exit
!  endif
! enddo
!!10 continue 
!! Obtaining the 4 appropriate XCPs for that spline segment
!if(j.ne.0.and.j.le.4)then
! xc(1) = xcp1(1) 
! xc(2) = xcp1(2) 
! xc(3) = xcp1(3) 
! xc(4) = xcp1(4) 
!! print*,'xc:',xc
!elseif(j.ge.4)then
! xc(1) = xcp1(j-3)
! xc(2) = xcp1(j-2)
! xc(3) = xcp1(j-1)
! xc(4) = xcp1(j)
!! print*,'xc:',xc
!endif
!! Use the solution 'tfinal' to calculate F_x(t) (or F_y(t)) for that spline segment.
!!  G(t) = a1(t^3) + a2(t^2) + a3(t) + a4 ; G(t) = G_x(t) (or G_y(t))
!!  G'(t) = 3a1(t^2) + 2a2(t) + a3
!! a1 = (1/6)*( -XCP1 + 3XCP2 - 3XCP3 + XCP4)
!! a2 = (1/6)*( 3XCP1 - 6XCP2 + 3XCP3)
!! a3 = (1/6)*(-3XCP1 + 3XCP3)
!! a4 = (1/6)*(  XCP1 + 4XCP2 + XCP3) 
!!---------------
!! Forming the cubic equation G(t) in t
!! print*,'xc before coeff calc:',xc
! a1 = ( -xc(1)  + (3*xc(2)) - (3*xc(3)) + xc(4))/6
! a2 = ( (3*xc(1)) - (6*xc(2)) + (3*xc(3)))/6
! a3 = ((-3*xc(1)) + (3*xc(3)))/6
! a4 = (   xc(1) + (4*xc(2)) + xc(3))/6 
!! print*,'a1,a2,a3,a4',a1,a2,a3,a4 
! gfunc = a1*(tfinal)**3 + a2*(tfinal)**2 + a3*(tfinal) + a4
!! gfunc is the yout for the given xin.
! yout = gfunc
!! print*,'yout using Newton-Raphson method:',yout
!! write(*,*)
!!endif
!youtarray(ia) = yout
!!print*,'ia,yout:',ia,yout
!!write(*,*)
!
!if(ia.eq.1)then
! youtarray(ia) = xcp1(2)
!elseif(ia.eq.na)then
! youtarray(ia) = xcp1(ncp1-1)
!endif 
!return 
!end subroutine curvline_intersec





















