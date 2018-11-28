library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;


library unisim;
use unisim.vcomponents.all;

entity comparator_generator is
generic(
    MXKEYHS     : integer := 224;
    MXPATID     : integer := 10;
    MNPATID     : integer := 6
);
port(

    reset                   : in  std_logic;

    key_hs                  : in  std_logic_vector (7 downto 0);
    ccode                   : in  std_logic_vector (11 downto 0);
    pattern                 : in  std_logic_vector (3 downto 0);

    pat_ly0                : out std_logic_vector (10 downto 0);
    pat_ly1                : out std_logic_vector (10 downto 0);
    pat_ly2                : out std_logic_vector (10 downto 0);
    pat_ly3                : out std_logic_vector (10 downto 0);
    pat_ly4                : out std_logic_vector (10 downto 0);
    pat_ly5                : out std_logic_vector (10 downto 0);

    cfeb_ly0                : out std_logic_vector (MXKEYHS-1 downto 0);
    cfeb_ly1                : out std_logic_vector (MXKEYHS-1 downto 0);
    cfeb_ly2                : out std_logic_vector (MXKEYHS-1 downto 0);
    cfeb_ly3                : out std_logic_vector (MXKEYHS-1 downto 0);
    cfeb_ly4                : out std_logic_vector (MXKEYHS-1 downto 0);
    cfeb_ly5                : out std_logic_vector (MXKEYHS-1 downto 0)

);
end comparator_generator;

architecture comparator_generator_arch of comparator_generator is

   type pat_ly_arr    is array (0 to 5) of std_logic_vector (10 downto 0);
   type cfeb_ly_arr   is array (0 to 5) of std_logic_vector (MXKEYHS-1 downto 0);

   signal pat_ly : pat_ly_arr;
   signal triad_ly : pat_ly_arr;
   signal cfeb_ly : cfeb_ly_arr;

   signal i_key_hs : integer range 0 to MXKEYHS-1 := 0;

   function unpack_subcode (
      subcode : in std_logic_vector(1 downto 0)
   ) return std_logic_vector is
      variable unpacked_triad : std_logic_vector(2 downto 0);
   begin

      if    (subcode="00") then unpacked_triad := "000";
      elsif (subcode="01") then unpacked_triad := "001";
      elsif (subcode="10") then unpacked_triad := "010";
      elsif (subcode="11") then unpacked_triad := "100";
      else                      unpacked_triad := "000";
      end if;

      return std_logic_vector(unpacked_triad);

   end;

begin

   i_key_hs <= to_integer(unsigned(key_hs));

   cfeb_ly0 <= cfeb_ly(0);
   cfeb_ly1 <= cfeb_ly(1);
   cfeb_ly2 <= cfeb_ly(2);
   cfeb_ly3 <= cfeb_ly(3);
   cfeb_ly4 <= cfeb_ly(4);
   cfeb_ly5 <= cfeb_ly(5);

   -- 1) decompose cccodes into 6 layers of hits, padded with zeroes for stupid vhdl
   --       - add a reset stage

   triad_ly(0) <= (others => '0') when (reset='1') else x"00" & unpack_subcode (ccode ( 1 downto  0));
   triad_ly(1) <= (others => '0') when (reset='1') else x"00" & unpack_subcode (ccode ( 3 downto  2));
   triad_ly(2) <= (others => '0') when (reset='1') else x"00" & unpack_subcode (ccode ( 5 downto  4));
   triad_ly(3) <= (others => '0') when (reset='1') else x"00" & unpack_subcode (ccode ( 7 downto  6));
   triad_ly(4) <= (others => '0') when (reset='1') else x"00" & unpack_subcode (ccode ( 9 downto  8));
   triad_ly(5) <= (others => '0') when (reset='1') else x"00" & unpack_subcode (ccode (11 downto 10));

   -- 2) shift 6 layers of triads

   process(pattern, triad_ly)
   begin
   if (pattern = x"A") then
      pat_ly(0) <= std_logic_vector(shift_left(unsigned(triad_ly(0)), 4 ));
      pat_ly(1) <= std_logic_vector(shift_left(unsigned(triad_ly(1)), 4 ));
      pat_ly(2) <= std_logic_vector(shift_left(unsigned(triad_ly(2)), 4 ));
      pat_ly(3) <= std_logic_vector(shift_left(unsigned(triad_ly(3)), 4 ));
      pat_ly(4) <= std_logic_vector(shift_left(unsigned(triad_ly(4)), 4 ));
      pat_ly(5) <= std_logic_vector(shift_left(unsigned(triad_ly(5)), 4 ));
   elsif (pattern = x"9") then
      pat_ly(0) <= std_logic_vector(shift_left(unsigned(triad_ly(0)), 6 ));
      pat_ly(1) <= std_logic_vector(shift_left(unsigned(triad_ly(1)), 5 ));
      pat_ly(2) <= std_logic_vector(shift_left(unsigned(triad_ly(2)), 4 ));
      pat_ly(3) <= std_logic_vector(shift_left(unsigned(triad_ly(3)), 4 ));
      pat_ly(4) <= std_logic_vector(shift_left(unsigned(triad_ly(4)), 3 ));
      pat_ly(5) <= std_logic_vector(shift_left(unsigned(triad_ly(5)), 2 ));
   elsif (pattern = x"8") then
      pat_ly(0) <= std_logic_vector(shift_left(unsigned(triad_ly(0)), 2 ));
      pat_ly(1) <= std_logic_vector(shift_left(unsigned(triad_ly(1)), 3 ));
      pat_ly(2) <= std_logic_vector(shift_left(unsigned(triad_ly(2)), 4 ));
      pat_ly(3) <= std_logic_vector(shift_left(unsigned(triad_ly(3)), 4 ));
      pat_ly(4) <= std_logic_vector(shift_left(unsigned(triad_ly(4)), 5 ));
      pat_ly(5) <= std_logic_vector(shift_left(unsigned(triad_ly(5)), 6 ));
   elsif (pattern = x"7") then
      pat_ly(0) <= std_logic_vector(shift_left(unsigned(triad_ly(0)), 8 ));
      pat_ly(1) <= std_logic_vector(shift_left(unsigned(triad_ly(1)), 7 ));
      pat_ly(2) <= std_logic_vector(shift_left(unsigned(triad_ly(2)), 5 ));
      pat_ly(3) <= std_logic_vector(shift_left(unsigned(triad_ly(3)), 3 ));
      pat_ly(4) <= std_logic_vector(shift_left(unsigned(triad_ly(4)), 1 ));
      pat_ly(5) <= std_logic_vector(shift_left(unsigned(triad_ly(5)), 0 ));
   elsif (pattern = x"6") then
      pat_ly(0) <= std_logic_vector(shift_left(unsigned(triad_ly(0)), 0 ));
      pat_ly(1) <= std_logic_vector(shift_left(unsigned(triad_ly(1)), 1 ));
      pat_ly(2) <= std_logic_vector(shift_left(unsigned(triad_ly(2)), 3 ));
      pat_ly(3) <= std_logic_vector(shift_left(unsigned(triad_ly(3)), 5 ));
      pat_ly(4) <= std_logic_vector(shift_left(unsigned(triad_ly(4)), 7 ));
      pat_ly(5) <= std_logic_vector(shift_left(unsigned(triad_ly(5)), 8 ));
   else
      pat_ly(0) <= (others => '1');
      pat_ly(1) <= (others => '1');
      pat_ly(2) <= (others => '1');
      pat_ly(3) <= (others => '1');
      pat_ly(4) <= (others => '1');
      pat_ly(5) <= (others => '1');
   end if;
   end process;

   pat_ly0 <=pat_ly(0);
   pat_ly1 <=pat_ly(1);
   pat_ly2 <=pat_ly(2);
   pat_ly3 <=pat_ly(3);
   pat_ly4 <=pat_ly(4);
   pat_ly5 <=pat_ly(5);

   lyassign : process(i_key_hs, pat_ly)
   begin

      lyloop : for ily in 0 to 5 loop
         -----------------------------------------------------------------------------------------------------------------------
         -- ME1b
         -----------------------------------------------------------------------------------------------------------------------

         -- 0 to 4
         if    (i_key_hs <= 4) then

            cfeb_ly(ily) (i_key_hs + 5 downto 0       ) <= pat_ly(ily) (10 downto (5-i_key_hs));
            cfeb_ly(ily) (MXKEYHS- 1 downto i_key_hs+6) <= (others => '0');

         -- 5 to 122
         elsif (i_key_hs >= 0+5 and i_key_hs <= 127-5) then

            cfeb_ly(ily) (i_key_hs - 6 downto 0       )   <= (others => '0');
            cfeb_ly(ily) (i_key_hs + 5 downto i_key_hs-5) <= pat_ly(ily);
            cfeb_ly(ily) (MXKEYHS- 1 downto i_key_hs+6)   <= (others => '0');

         -- 123 to 127
         elsif (i_key_hs >=123 and i_key_hs <=127 ) then

            cfeb_ly(ily) (i_key_hs - 6 downto 0       ) <= (others => '0');
            cfeb_ly(ily) (127        downto i_key_hs-5) <= pat_ly(ily) (5+127-i_key_hs downto 0);
            cfeb_ly(ily) (MXKEYHS- 1 downto 128     )   <= (others => '0');

         -----------------------------------------------------------------------------------------------------------------------
         -- ME1a
         -----------------------------------------------------------------------------------------------------------------------

         -- 128 to 132
         elsif (i_key_hs >=128 and i_key_hs <= 132 ) then

            cfeb_ly(ily) (127 downto 0)               <= (others => '0');
            cfeb_ly(ily) (i_key_hs + 5 downto 128     ) <= pat_ly(ily) (10 downto (128+5-i_key_hs));
            cfeb_ly(ily) (MXKEYHS- 1 downto i_key_hs+6) <= (others => '0');

         -- 133 to 218
         elsif (i_key_hs >=128+5 and i_key_hs <= 223-5 ) then

            cfeb_ly(ily) (i_key_hs - 6 downto 0       ) <= (others => '0');
            cfeb_ly(ily) (i_key_hs + 5 downto i_key_hs-5) <= pat_ly(ily);
            cfeb_ly(ily) (MXKEYHS- 1 downto i_key_hs+6) <= (others => '0');

         -- 219 - 223
         elsif (i_key_hs >=223-4) then

            cfeb_ly(ily) (i_key_hs - 6 downto 0       ) <= (others => '0');
            cfeb_ly(ily) (223        downto i_key_hs-5) <= pat_ly(ily) (5+223-i_key_hs downto 0);

         else

            cfeb_ly(ily) <= (others => '0');

         end if;
      end loop;
   end process lyassign;

end comparator_generator_arch;

