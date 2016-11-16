declare i32 @printf(i8*,...) nounwind
;x
@x = global i64 0, align 4

;x__printf_constant
@x__printf_constant = constant [10 x i8] c"x = %lld\0a\00"

;z
@z = global i64 0, align 4

;z__printf_constant
@z__printf_constant = constant [10 x i8] c"z = %lld\0a\00"

;f
define i64 @f(i64 %x) {
   %add = add i64 %x, 1
   ret i64 %add
}

;y
@y = global i64 0, align 4

;y__printf_constant
@y__printf_constant = constant [10 x i8] c"y = %lld\0a\00"

;g
define i64 @g(i64 %x) {
   %slt = icmp slt i64 %x, 0
   br i1 %slt, label %label1, label %label2
 label1:
   br label %label3
 label2:
   %mul = mul i64 %x, %x
   br label %label3
 label3:
   %phi = phi i64 [1, %label1],[%mul, %label2]
   ret i64 %phi
}

;fib
define i64 @fib(i64 %n) {
   %sle = icmp sle i64 %n, 1
   br i1 %sle, label %label4, label %label5
 label4:
   br label %label6
 label5:
   %sub = sub i64 %n, 1
   %call = call i64 @fib(i64 %sub)
   %sub0 = sub i64 %n, 2
   %call0 = call i64 @fib(i64 %sub0)
   %add = add i64 %call, %call0
   br label %label6
 label6:
   %phi = phi i64 [%n, %label4],[%add, %label5]
   ret i64 %phi
}

;tmp
@tmp = global i64 0, align 4

;tmp__printf_constant
@tmp__printf_constant = constant [12 x i8] c"tmp = %lld\0a\00"

;h
define i64 @h(i64 %x, i64 %y) {
   %sle = icmp sle i64 %x, 0
   br i1 %sle, label %label7, label %label8
 label7:
   br label %label9
 label8:
   %sub = sub i64 %x, %y
   %call = call i64 @k(i64 %sub, i64 %y)
   br label %label9
 label9:
   %phi = phi i64 [%y, %label7],[%call, %label8]
   ret i64 %phi
}

;k
define i64 @k(i64 %x, i64 %y) {
   %sle = icmp sle i64 %x, 0
   br i1 %sle, label %label10, label %label11
 label10:
   br label %label12
 label11:
   %call = call i64 @h(i64 %x, i64 %y)
   %add = add i64 %call, 1
   br label %label12
 label12:
   %phi = phi i64 [%y, %label10],[%add, %label11]
   ret i64 %phi
}

;u
@u = global i64 0, align 4

;u__printf_constant
@u__printf_constant = constant [10 x i8] c"u = %lld\0a\00"

;mod
define i64 @mod(i64 %x, i64 %y) {
   %sdiv = sdiv i64 %x, %y
   %mul = mul i64 %sdiv, %y
   %sub = sub i64 %x, %mul
   ret i64 %sub
}

;abs
define i64 @abs(i64 %x) {
   %slt = icmp slt i64 %x, 0
   br i1 %slt, label %label13, label %label14
 label13:
   %sub = sub i64 0, %x
   br label %label15
 label14:
   br label %label15
 label15:
   %phi = phi i64 [%sub, %label13],[%x, %label14]
   ret i64 %phi
}

;gcd
define i64 @gcd(i64 %x, i64 %y) {
   %call = call i64 @abs(i64 %x)
   %call0 = call i64 @abs(i64 %y)
   %sle = icmp sle i64 %call, %call0
   br i1 %sle, label %label16, label %label17
 label16:
   %call1 = call i64 @gcdaux(i64 %call, i64 %call0)
   br label %label18
 label17:
   %call2 = call i64 @gcdaux(i64 %call0, i64 %call)
   br label %label18
 label18:
   %phi = phi i64 [%call1, %label16],[%call2, %label17]
   ret i64 %phi
}

;gcdaux
define i64 @gcdaux(i64 %x, i64 %y) {
   %eq = icmp eq i64 %x, 0
   br i1 %eq, label %label19, label %label20
 label19:
   br label %label21
 label20:
   %call = call i64 @mod(i64 %y, i64 %x)
   %call0 = call i64 @gcdaux(i64 %call, i64 %x)
   br label %label21
 label21:
   %phi = phi i64 [%y, %label19],[%call0, %label20]
   ret i64 %phi
}

;testgcd1
@testgcd1 = global i64 0, align 4

;testgcd1__printf_constant
@testgcd1__printf_constant = constant [17 x i8] c"testgcd1 = %lld\0a\00"

;testgcd2
@testgcd2 = global i64 0, align 4

;testgcd2__printf_constant
@testgcd2__printf_constant = constant [17 x i8] c"testgcd2 = %lld\0a\00"

;gy
@gy = global i64 0, align 4

;gy__printf_constant
@gy__printf_constant = constant [11 x i8] c"gy = %lld\0a\00"

;fg
define i64 @fg(i64 %x) {
   %load = load i64* @gy, align 4
   %add = add i64 %load, %x
   ret i64 %add
}

;gg
@gg = global i64 0, align 4

;gg__printf_constant
@gg__printf_constant = constant [11 x i8] c"gg = %lld\0a\00"

;testtest
define i64 @testtest(i64 %x, i64 %y) {
   %eq = icmp eq i64 %x, %y
   br i1 %eq, label %label22, label %label23
 label22:
   %sub = sub i64 0, 1
   br label %label24
 label23:
   %sle = icmp sle i64 %x, %y
   br i1 %sle, label %label25, label %label26
 label25:
   %sub0 = sub i64 %y, 5
   %sle0 = icmp sle i64 %x, %sub0
   br i1 %sle0, label %label28, label %label29
 label28:
   br label %label30
 label29:
   br label %label30
 label30:
   %phi = phi i64 [0, %label28],[1, %label29]
   br label %label27
 label26:
   %add = add i64 %y, 5
   %sge = icmp sge i64 %x, %add
   br i1 %sge, label %label31, label %label32
 label31:
   br label %label33
 label32:
   br label %label33
 label33:
   %phi0 = phi i64 [2, %label31],[3, %label32]
   br label %label27
 label27:
   %phi1 = phi i64 [%phi, %label30],[%phi0, %label33]
   br label %label24
 label24:
   %phi2 = phi i64 [%sub, %label22],[%phi1, %label27]
   ret i64 %phi2
}

;testtest1
@testtest1 = global i64 0, align 4

;testtest1__printf_constant
@testtest1__printf_constant = constant [18 x i8] c"testtest1 = %lld\0a\00"

;testtest2
@testtest2 = global i64 0, align 4

;testtest2__printf_constant
@testtest2__printf_constant = constant [18 x i8] c"testtest2 = %lld\0a\00"

;testtest3
@testtest3 = global i64 0, align 4

;testtest3__printf_constant
@testtest3__printf_constant = constant [18 x i8] c"testtest3 = %lld\0a\00"

;testtest4
@testtest4 = global i64 0, align 4

;testtest4__printf_constant
@testtest4__printf_constant = constant [18 x i8] c"testtest4 = %lld\0a\00"

;testtest5
@testtest5 = global i64 0, align 4

;testtest5__printf_constant
@testtest5__printf_constant = constant [18 x i8] c"testtest5 = %lld\0a\00"

;testtestb
define i64 @testtestb(i64 %x, i64 %y) {
   %eq = icmp eq i64 %x, %y
   br i1 %eq, label %label34, label %label35
 label34:
   %sub = sub i64 0, 1
   br label %label36
 label35:
   %sub0 = sub i64 %x, %y
   %sub1 = sub i64 %y, %x
   %sle = icmp sle i64 %x, %y
   br i1 %sle, label %label37, label %label38
 label37:
   %sub2 = sub i64 %y, 5
   %sle0 = icmp sle i64 %x, %sub2
   br i1 %sle0, label %label40, label %label41
 label40:
   br label %label42
 label41:
   br label %label42
 label42:
   %phi = phi i64 [%sub0, %label40],[1, %label41]
   br label %label39
 label38:
   %add = add i64 %y, 5
   %sge = icmp sge i64 %x, %add
   br i1 %sge, label %label43, label %label44
 label43:
   br label %label45
 label44:
   br label %label45
 label45:
   %phi0 = phi i64 [%sub1, %label43],[3, %label44]
   br label %label39
 label39:
   %phi1 = phi i64 [%phi, %label42],[%phi0, %label45]
   br label %label36
 label36:
   %phi2 = phi i64 [%sub, %label34],[%phi1, %label39]
   ret i64 %phi2
}

;testtestb1
@testtestb1 = global i64 0, align 4

;testtestb1__printf_constant
@testtestb1__printf_constant = constant [19 x i8] c"testtestb1 = %lld\0a\00"

;testtestb2
@testtestb2 = global i64 0, align 4

;testtestb2__printf_constant
@testtestb2__printf_constant = constant [19 x i8] c"testtestb2 = %lld\0a\00"

;testtestb3
@testtestb3 = global i64 0, align 4

;testtestb3__printf_constant
@testtestb3__printf_constant = constant [19 x i8] c"testtestb3 = %lld\0a\00"

;testtestb4
@testtestb4 = global i64 0, align 4

;testtestb4__printf_constant
@testtestb4__printf_constant = constant [19 x i8] c"testtestb4 = %lld\0a\00"

;testtestb5
@testtestb5 = global i64 0, align 4

;testtestb5__printf_constant
@testtestb5__printf_constant = constant [19 x i8] c"testtestb5 = %lld\0a\00"

;fact
define i64 @fact(i64 %n) {
   %sle = icmp sle i64 %n, 0
   br i1 %sle, label %label46, label %label47
 label46:
   br label %label48
 label47:
   %sub = sub i64 %n, 1
   %call = call i64 @fact(i64 %sub)
   %mul = mul i64 %n, %call
   br label %label48
 label48:
   %phi = phi i64 [1, %label46],[%mul, %label47]
   ret i64 %phi
}

;f10
@f10 = global i64 0, align 4

;f10__printf_constant
@f10__printf_constant = constant [12 x i8] c"f10 = %lld\0a\00"

;f20
@f20 = global i64 0, align 4

;f20__printf_constant
@f20__printf_constant = constant [12 x i8] c"f20 = %lld\0a\00"

;f30
@f30 = global i64 0, align 4

;f30__printf_constant
@f30__printf_constant = constant [12 x i8] c"f30 = %lld\0a\00"

;f100
@f100 = global i64 0, align 4

;f100__printf_constant
@f100__printf_constant = constant [13 x i8] c"f100 = %lld\0a\00"

;f1000
@f1000 = global i64 0, align 4

;f1000__printf_constant
@f1000__printf_constant = constant [14 x i8] c"f1000 = %lld\0a\00"

;pow
define i64 @pow(i64 %x, i64 %y) {
   %sle = icmp sle i64 %y, 0
   br i1 %sle, label %label49, label %label50
 label49:
   br label %label51
 label50:
   %sub = sub i64 %y, 1
   %call = call i64 @pow(i64 %x, i64 %sub)
   %mul = mul i64 %x, %call
   br label %label51
 label51:
   %phi = phi i64 [1, %label49],[%mul, %label50]
   ret i64 %phi
}

;test32
@test32 = global i64 0, align 4

;test32__printf_constant
@test32__printf_constant = constant [15 x i8] c"test32 = %lld\0a\00"

;test
@test = global i64 0, align 4

;test__printf_constant
@test__printf_constant = constant [13 x i8] c"test = %lld\0a\00"

;test33
@test33 = global i64 0, align 4

;test33__printf_constant
@test33__printf_constant = constant [15 x i8] c"test33 = %lld\0a\00"

;test62
@test62 = global i64 0, align 4

;test62__printf_constant
@test62__printf_constant = constant [15 x i8] c"test62 = %lld\0a\00"

;test63
@test63 = global i64 0, align 4

;test63__printf_constant
@test63__printf_constant = constant [15 x i8] c"test63 = %lld\0a\00"

;test64
@test64 = global i64 0, align 4

;test64__printf_constant
@test64__printf_constant = constant [15 x i8] c"test64 = %lld\0a\00"

;test65
@test65 = global i64 0, align 4

;test65__printf_constant
@test65__printf_constant = constant [15 x i8] c"test65 = %lld\0a\00"

define i32 @main(i32 %argc, i8** %argv) {
   store i64 2, i64* @x, align 4
   %call = call i32 (i8*,...)* @printf(i8* getelementptr([10 x i8]* @x__printf_constant, i32 0, i32 0), i64 2)
   %load = load i64* @x, align 4
   %add = add i64 %load, 1
   store i64 %add, i64* @x, align 4
   %call0 = call i32 (i8*,...)* @printf(i8* getelementptr([10 x i8]* @x__printf_constant, i32 0, i32 0), i64 %add)
   %load0 = load i64* @x, align 4
   store i64 %load0, i64* @z, align 4
   %call1 = call i32 (i8*,...)* @printf(i8* getelementptr([10 x i8]* @z__printf_constant, i32 0, i32 0), i64 %load0)
   %load1 = load i64* @x, align 4
   %call2 = call i64 @f(i64 %load1)
   store i64 %call2, i64* @z, align 4
   %call3 = call i32 (i8*,...)* @printf(i8* getelementptr([10 x i8]* @z__printf_constant, i32 0, i32 0), i64 %call2)
   %load2 = load i64* @x, align 4
   %call4 = call i64 @f(i64 %load2)
   %load3 = load i64* @x, align 4
   %mul = mul i64 %call4, %load3
   store i64 %mul, i64* @y, align 4
   %call5 = call i32 (i8*,...)* @printf(i8* getelementptr([10 x i8]* @y__printf_constant, i32 0, i32 0), i64 %mul)
   %load4 = load i64* @y, align 4
   %call6 = call i64 @g(i64 %load4)
   store i64 %call6, i64* @z, align 4
   %call7 = call i32 (i8*,...)* @printf(i8* getelementptr([10 x i8]* @z__printf_constant, i32 0, i32 0), i64 %call6)
   %call8 = call i64 @fib(i64 25)
   store i64 %call8, i64* @tmp, align 4
   %call9 = call i32 (i8*,...)* @printf(i8* getelementptr([12 x i8]* @tmp__printf_constant, i32 0, i32 0), i64 %call8)
   %call10 = call i64 @h(i64 10, i64 1)
   store i64 %call10, i64* @u, align 4
   %call11 = call i32 (i8*,...)* @printf(i8* getelementptr([10 x i8]* @u__printf_constant, i32 0, i32 0), i64 %call10)
   %call12 = call i64 @gcdaux(i64 42, i64 91)
   store i64 %call12, i64* @testgcd1, align 4
   %call13 = call i32 (i8*,...)* @printf(i8* getelementptr([17 x i8]* @testgcd1__printf_constant, i32 0, i32 0), i64 %call12)
   %call14 = call i64 @gcdaux(i64 421264322, i64 912356724)
   store i64 %call14, i64* @testgcd2, align 4
   %call15 = call i32 (i8*,...)* @printf(i8* getelementptr([17 x i8]* @testgcd2__printf_constant, i32 0, i32 0), i64 %call14)
   store i64 2, i64* @gy, align 4
   %call16 = call i32 (i8*,...)* @printf(i8* getelementptr([11 x i8]* @gy__printf_constant, i32 0, i32 0), i64 2)
   %call17 = call i64 @fg(i64 3)
   store i64 %call17, i64* @gg, align 4
   %call18 = call i32 (i8*,...)* @printf(i8* getelementptr([11 x i8]* @gg__printf_constant, i32 0, i32 0), i64 %call17)
   %sub = sub i64 0, 6
   %call19 = call i64 @testtest(i64 %sub, i64 0)
   store i64 %call19, i64* @testtest1, align 4
   %call20 = call i32 (i8*,...)* @printf(i8* getelementptr([18 x i8]* @testtest1__printf_constant, i32 0, i32 0), i64 %call19)
   %sub0 = sub i64 0, 1
   %call21 = call i64 @testtest(i64 %sub0, i64 0)
   store i64 %call21, i64* @testtest2, align 4
   %call22 = call i32 (i8*,...)* @printf(i8* getelementptr([18 x i8]* @testtest2__printf_constant, i32 0, i32 0), i64 %call21)
   %call23 = call i64 @testtest(i64 0, i64 0)
   store i64 %call23, i64* @testtest3, align 4
   %call24 = call i32 (i8*,...)* @printf(i8* getelementptr([18 x i8]* @testtest3__printf_constant, i32 0, i32 0), i64 %call23)
   %call25 = call i64 @testtest(i64 1, i64 0)
   store i64 %call25, i64* @testtest4, align 4
   %call26 = call i32 (i8*,...)* @printf(i8* getelementptr([18 x i8]* @testtest4__printf_constant, i32 0, i32 0), i64 %call25)
   %call27 = call i64 @testtest(i64 6, i64 0)
   store i64 %call27, i64* @testtest5, align 4
   %call28 = call i32 (i8*,...)* @printf(i8* getelementptr([18 x i8]* @testtest5__printf_constant, i32 0, i32 0), i64 %call27)
   %sub1 = sub i64 0, 6
   %call29 = call i64 @testtestb(i64 %sub1, i64 0)
   store i64 %call29, i64* @testtestb1, align 4
   %call30 = call i32 (i8*,...)* @printf(i8* getelementptr([19 x i8]* @testtestb1__printf_constant, i32 0, i32 0), i64 %call29)
   %sub2 = sub i64 0, 1
   %call31 = call i64 @testtestb(i64 %sub2, i64 0)
   store i64 %call31, i64* @testtestb2, align 4
   %call32 = call i32 (i8*,...)* @printf(i8* getelementptr([19 x i8]* @testtestb2__printf_constant, i32 0, i32 0), i64 %call31)
   %call33 = call i64 @testtestb(i64 0, i64 0)
   store i64 %call33, i64* @testtestb3, align 4
   %call34 = call i32 (i8*,...)* @printf(i8* getelementptr([19 x i8]* @testtestb3__printf_constant, i32 0, i32 0), i64 %call33)
   %call35 = call i64 @testtestb(i64 1, i64 0)
   store i64 %call35, i64* @testtestb4, align 4
   %call36 = call i32 (i8*,...)* @printf(i8* getelementptr([19 x i8]* @testtestb4__printf_constant, i32 0, i32 0), i64 %call35)
   %call37 = call i64 @testtestb(i64 6, i64 0)
   store i64 %call37, i64* @testtestb5, align 4
   %call38 = call i32 (i8*,...)* @printf(i8* getelementptr([19 x i8]* @testtestb5__printf_constant, i32 0, i32 0), i64 %call37)
   %call39 = call i64 @fact(i64 10)
   store i64 %call39, i64* @f10, align 4
   %call40 = call i32 (i8*,...)* @printf(i8* getelementptr([12 x i8]* @f10__printf_constant, i32 0, i32 0), i64 %call39)
   %call41 = call i64 @fact(i64 20)
   store i64 %call41, i64* @f20, align 4
   %call42 = call i32 (i8*,...)* @printf(i8* getelementptr([12 x i8]* @f20__printf_constant, i32 0, i32 0), i64 %call41)
   %call43 = call i64 @fact(i64 30)
   store i64 %call43, i64* @f30, align 4
   %call44 = call i32 (i8*,...)* @printf(i8* getelementptr([12 x i8]* @f30__printf_constant, i32 0, i32 0), i64 %call43)
   %call45 = call i64 @fact(i64 100)
   store i64 %call45, i64* @f100, align 4
   %call46 = call i32 (i8*,...)* @printf(i8* getelementptr([13 x i8]* @f100__printf_constant, i32 0, i32 0), i64 %call45)
   %call47 = call i64 @fact(i64 1000)
   store i64 %call47, i64* @f1000, align 4
   %call48 = call i32 (i8*,...)* @printf(i8* getelementptr([14 x i8]* @f1000__printf_constant, i32 0, i32 0), i64 %call47)
   %call49 = call i64 @pow(i64 2, i64 32)
   store i64 %call49, i64* @test32, align 4
   %call50 = call i32 (i8*,...)* @printf(i8* getelementptr([15 x i8]* @test32__printf_constant, i32 0, i32 0), i64 %call49)
   %load5 = load i64* @test32, align 4
   %eq = icmp eq i64 %load5, 0
   br i1 %eq, label %label52, label %label53
 label52:
   br label %label54
 label53:
   br label %label54
 label54:
   %phi = phi i64 [0, %label52],[1, %label53]
   store i64 %phi, i64* @test, align 4
   %call51 = call i32 (i8*,...)* @printf(i8* getelementptr([13 x i8]* @test__printf_constant, i32 0, i32 0), i64 %phi)
   %call52 = call i64 @pow(i64 2, i64 33)
   store i64 %call52, i64* @test33, align 4
   %call53 = call i32 (i8*,...)* @printf(i8* getelementptr([15 x i8]* @test33__printf_constant, i32 0, i32 0), i64 %call52)
   %load6 = load i64* @test33, align 4
   %eq0 = icmp eq i64 %load6, 0
   br i1 %eq0, label %label55, label %label56
 label55:
   br label %label57
 label56:
   br label %label57
 label57:
   %phi0 = phi i64 [0, %label55],[1, %label56]
   store i64 %phi0, i64* @test, align 4
   %call54 = call i32 (i8*,...)* @printf(i8* getelementptr([13 x i8]* @test__printf_constant, i32 0, i32 0), i64 %phi0)
   %call55 = call i64 @pow(i64 2, i64 62)
   store i64 %call55, i64* @test62, align 4
   %call56 = call i32 (i8*,...)* @printf(i8* getelementptr([15 x i8]* @test62__printf_constant, i32 0, i32 0), i64 %call55)
   %load7 = load i64* @test62, align 4
   %eq1 = icmp eq i64 %load7, 0
   br i1 %eq1, label %label58, label %label59
 label58:
   br label %label60
 label59:
   br label %label60
 label60:
   %phi1 = phi i64 [0, %label58],[1, %label59]
   store i64 %phi1, i64* @test, align 4
   %call57 = call i32 (i8*,...)* @printf(i8* getelementptr([13 x i8]* @test__printf_constant, i32 0, i32 0), i64 %phi1)
   %call58 = call i64 @pow(i64 2, i64 63)
   store i64 %call58, i64* @test63, align 4
   %call59 = call i32 (i8*,...)* @printf(i8* getelementptr([15 x i8]* @test63__printf_constant, i32 0, i32 0), i64 %call58)
   %load8 = load i64* @test63, align 4
   %eq2 = icmp eq i64 %load8, 0
   br i1 %eq2, label %label61, label %label62
 label61:
   br label %label63
 label62:
   br label %label63
 label63:
   %phi2 = phi i64 [0, %label61],[1, %label62]
   store i64 %phi2, i64* @test, align 4
   %call60 = call i32 (i8*,...)* @printf(i8* getelementptr([13 x i8]* @test__printf_constant, i32 0, i32 0), i64 %phi2)
   %call61 = call i64 @pow(i64 2, i64 64)
   store i64 %call61, i64* @test64, align 4
   %call62 = call i32 (i8*,...)* @printf(i8* getelementptr([15 x i8]* @test64__printf_constant, i32 0, i32 0), i64 %call61)
   %load9 = load i64* @test64, align 4
   %eq3 = icmp eq i64 %load9, 0
   br i1 %eq3, label %label64, label %label65
 label64:
   br label %label66
 label65:
   br label %label66
 label66:
   %phi3 = phi i64 [0, %label64],[1, %label65]
   store i64 %phi3, i64* @test, align 4
   %call63 = call i32 (i8*,...)* @printf(i8* getelementptr([13 x i8]* @test__printf_constant, i32 0, i32 0), i64 %phi3)
   %call64 = call i64 @pow(i64 2, i64 65)
   store i64 %call64, i64* @test65, align 4
   %call65 = call i32 (i8*,...)* @printf(i8* getelementptr([15 x i8]* @test65__printf_constant, i32 0, i32 0), i64 %call64)
   %load10 = load i64* @test65, align 4
   %eq4 = icmp eq i64 %load10, 0
   br i1 %eq4, label %label67, label %label68
 label67:
   br label %label69
 label68:
   br label %label69
 label69:
   %phi4 = phi i64 [0, %label67],[1, %label68]
   store i64 %phi4, i64* @test, align 4
   %call66 = call i32 (i8*,...)* @printf(i8* getelementptr([13 x i8]* @test__printf_constant, i32 0, i32 0), i64 %phi4)
ret i32 0
}
