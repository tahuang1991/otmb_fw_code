library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ccode_checker is
port(

    valid                  : in std_logic;
    pat_expect             : in std_logic_vector (3 downto 0);
    pat_found              : in std_logic_vector (3 downto 0);
    ccode_expect            : in std_logic_vector (11 downto 0);
    ccode_found             : in std_logic_vector (11 downto 0);
    keyhs_expect            : in std_logic_vector (7 downto 0);
    keyhs_found             : in std_logic_vector (7 downto 0);

    match                   : out std_logic

);
end ccode_checker;

architecture ccode_checker_arch of ccode_checker is

    signal keyhs_expect_m1    : std_logic_vector (7 downto 0);
    signal keyhs_expect_m2    : std_logic_vector (7 downto 0);

    signal ccode_expect_m1    : std_logic_vector (11 downto 0);
    signal ccode_expect_m2    : std_logic_vector (11 downto 0);

    function shift_ccode (
	layer_ccode : in std_logic_vector(1 downto 0);
	shift : in integer
	) return std_logic_vector is
	    variable shifted : std_logic_vector(1 downto 0);
	begin

	    if (shift=0) then
		shifted := layer_ccode;
	    elsif (shift=1) then
		if    (layer_ccode="00") then shifted := "00";
		elsif (layer_ccode="01") then shifted := "10";
		elsif (layer_ccode="10") then shifted := "11";
		elsif (layer_ccode="11") then shifted := "00";
		end if;
	    elsif (shift=2) then
		if    (layer_ccode="00") then shifted := "00";
		elsif (layer_ccode="01") then shifted := "11";
		elsif (layer_ccode="10") then shifted := "00";
		elsif (layer_ccode="11") then shifted := "00";
		end if;
	    else
		shifted := "000";
	    end if;

	return std_logic_vector(shifted);
    end;

begin

    keyhs_expect_m1 <= std_logic_vector(unsigned(keyhs_expect) - 1);
    keyhs_expect_m2 <= std_logic_vector(unsigned(keyhs_expect) - 2);

    ccode_expect_m1(1  downto  0) <= shift_ccode(ccode_expect(1  downto  0) ,1);
    ccode_expect_m1(3  downto  2) <= shift_ccode(ccode_expect(3  downto  2) ,1);
    ccode_expect_m1(5  downto  4) <= shift_ccode(ccode_expect(5  downto  4) ,1);
    ccode_expect_m1(7  downto  6) <= shift_ccode(ccode_expect(7  downto  6) ,1);
    ccode_expect_m1(9  downto  8) <= shift_ccode(ccode_expect(9  downto  8) ,1);
    ccode_expect_m1(11 downto 10) <= shift_ccode(ccode_expect(11 downto 10) ,1);

    ccode_expect_m2(1  downto  0) <= shift_ccode(ccode_expect(1  downto  0) ,2);
    ccode_expect_m2(3  downto  2) <= shift_ccode(ccode_expect(3  downto  2) ,2);
    ccode_expect_m2(5  downto  4) <= shift_ccode(ccode_expect(5  downto  4) ,2);
    ccode_expect_m2(7  downto  6) <= shift_ccode(ccode_expect(7  downto  6) ,2);
    ccode_expect_m2(9  downto  8) <= shift_ccode(ccode_expect(9  downto  8) ,2);
    ccode_expect_m2(11 downto 10) <= shift_ccode(ccode_expect(11 downto 10) ,2);

    match <= '1' when
               valid='1' and (pat_expect = pat_found) and
	    (((keyhs_expect    = keyhs_found) and (ccode_expect = ccode_found)) or
             ((keyhs_expect_m1 = keyhs_found) and (ccode_expect_m1 = ccode_found)) or
             ((keyhs_expect_m2 = keyhs_found) and (ccode_expect_m2 = ccode_found)))
	    else '0';

end ccode_checker_arch;


