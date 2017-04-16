#include <avr/io.h>
#include <util/delay.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include "data_types.h"
#include "display_sda5708.h"

/** Structure for holding the key state */
struct key_state
{
    u8 old;
    u8 new;
};

static void gpio_init(void);
static void set_phase_increment(const u16 value);
static void update_display(const u16 phase_inc);

int main(void)
{
    struct key_state key_plus = { 0u, 0u };
    struct key_state key_minus = { 0u, 0u };

    u16 phase_inc = 0u;
    u16 new_phase_inc = 0u;

    /* Counter for counting time of pressed key */
    u8 ms_cnt = 0u;

    /* Disable interrupts */
    cli();

    /* Initialize the display */
    display_sda5708_init();

    /* Initialization */
    gpio_init();

    /* Reset CPLD */
    PORTB &= (u8)(~_BV(PB4));
    PORTB |= (u8)(_BV(PB4));

    /* Set first phase increment */
    set_phase_increment(phase_inc);
    update_display(phase_inc);

    /* Read keys */
    key_plus.old = (0u == (PINE & _BV(PE1)));
    key_minus.old = (0u == (PINE & _BV(PE2)));

    while (1)
    {
        _delay_ms(10.0);

        new_phase_inc = phase_inc;

        /* Read new state of the keys */
        key_plus.new = (0u == (PINE & _BV(PE1)));
        key_minus.new = (0u == (PINE & _BV(PE2)));

        /* Check for key test */
        if ((0u != key_plus.new) && (0u != key_minus.new))
        {
            display_sda5708_printf("Key test");
        }
        else
        {
            /* Check, if key "plus" pressed */
            if ((0u == key_plus.old) && (key_plus.old != key_plus.new))
            {
                ++new_phase_inc;
            }

            /* Check, if key "minus" pressed */
            if ((0u == key_minus.old) && (key_minus.old != key_minus.new))
            {
                --new_phase_inc;
            }

            /* If some of the keys pressed, count the time */
            if ((0u != key_plus.new) || (0u != key_minus.new))
            {
                /* Count the time and prevent overflow */
                if (ms_cnt < 200u)
                {
                    ms_cnt += 10;
                }
            }
            else
            {
                ms_cnt = 0u;
            }

            /* Check for accelerating the phase increment */
            if (ms_cnt >= 100u)
            {
                if (0u != key_plus.new)
                {
                    new_phase_inc += 23u;
                }
                else
                {
                    new_phase_inc -= 23u;
                }
            }

            /* Save new state, it is old now */
            key_plus.old = key_plus.new;
            key_minus.old = key_minus.new;

            /* Update state, if the phase increment has been changed */
            if (new_phase_inc != phase_inc)
            {
                phase_inc = new_phase_inc;
                set_phase_increment(phase_inc);
                update_display(phase_inc);
            }
        }
    }

    return 0;
}

static void gpio_init(void)
{
    /* Port A as output */
    DDRA = 0xFFu;       /* Low byte of phase increment */
    PORTA = 0u;

    /* Port C as output */
    DDRC = 0xFFu;       /* High byte of phase increment */
    PORTC = 0u;

    /* Pins of port E as output */
    DDRE |= (u8)(_BV(PE0));     /* Latch clock */
    PORTE &= (u8)(~_BV(PE0));

    /* Pins of port E as input */
    DDRE &= (u8)(~_BV(PE1));    /* Key + */
    DDRE &= (u8)(~_BV(PE2));    /* Key - */

    /* Pins of port B as output */
    DDRB |= (u8)(_BV(PB4));     /* CPLD reset */
    PORTB &= (u8)(~_BV(PB4));

    return;
}

static void set_phase_increment(const u16 value)
{
    /* Set low and high parts of the phase increment */
    PORTA = (u8)(value & 0x00FFu);
    PORTC = (u8)((value >> 8u) & 0x00FFu);

    /* Generate latch clock pulse */
    PORTE &= (u8)(~_BV(PE0));
    PORTE |= (u8)(_BV(PE0));
    PORTE &= (u8)(~_BV(PE0));

    return;
}

static void update_display(const u16 phase_inc)
{
    const double base_freq = 41.343689f;
    const double step = (double)(phase_inc);

    double output_freq = 0.0f;
    char buffer[16u];

    output_freq = (base_freq * step);

    if (0 < snprintf(&buffer[0u], (sizeof(buffer) - 1), "%lf", output_freq))
    {
        display_sda5708_printf(&buffer[0u]);
    }
    else
    {
        display_sda5708_printf("Error");
    }
}

