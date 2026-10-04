if global.current != 0
    global.current--;
else
{
    if global.page != 1
    {
    global.current = 3;
    global.page--;
    event_user(0);
    }
}

